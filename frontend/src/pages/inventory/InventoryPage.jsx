import { useState, useEffect, useCallback } from 'react'
import { useSearchParams } from 'react-router-dom'
import { AdjustmentsHorizontalIcon } from '@heroicons/react/24/outline'
import { useApi, usePagination } from '../../hooks/useApi'
import Modal from '../../components/ui/Modal'
import Pagination from '../../components/ui/Pagination'
import SearchInput from '../../components/ui/SearchInput'
import { TableSkeleton } from '../../components/ui/Skeleton'
import { useAuth } from '../../context/AuthContext'
import { formatCurrency, stockStatus } from '../../utils/format'
import toast from 'react-hot-toast'
import { useTranslation } from 'react-i18next'

function AdjustForm({ medicines, onSubmit, loading }) {
  const { t } = useTranslation()
  const [form, setForm] = useState({ medicine_id: '', type: 'add', quantity: '', reason: '', notes: '' })
  const [medSearch, setMedSearch] = useState('')
  const [medOpen, setMedOpen] = useState(false)
  const set = (k, v) => setForm(f => ({ ...f, [k]: v }))

  const filteredMeds = medicines.filter(m => {
    const q = medSearch.toLowerCase()
    return (m.name_ar || '').includes(medSearch) || (m.name || '').toLowerCase().includes(q) || (m.sku || '').toLowerCase().includes(q)
  })

  const selectedMed = medicines.find(m => m.id === form.medicine_id)

  const handleMedSelect = (m) => {
    set('medicine_id', m.id)
    setMedSearch('')
    setMedOpen(false)
  }

  const handleSubmit = (e) => {
    e.preventDefault()
    if (!form.medicine_id) return toast.error(t('inventory.required_medicine'))
    if (!form.quantity || form.quantity <= 0) return toast.error(t('inventory.required_quantity'))
    if (!form.reason.trim()) return toast.error(t('inventory.required_reason'))
    onSubmit(form)
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <div className="relative">
        <label className="label">{t('inventory.col_medicine')} *</label>
        <input
          type="text"
          className="input"
          placeholder={selectedMed ? (selectedMed.name_ar || selectedMed.name) : t('common.search') + '...'}
          value={medOpen ? medSearch : ''}
          onFocus={() => setMedOpen(true)}
          onChange={e => { setMedSearch(e.target.value); setMedOpen(true) }}
          onBlur={() => setTimeout(() => setMedOpen(false), 150)}
          style={{ color: !medOpen && selectedMed ? 'inherit' : undefined }}
        />
        {!medOpen && selectedMed && (
          <div className="absolute inset-0 top-6 flex items-center px-3 pointer-events-none">
            <span className="text-sm text-gray-900 dark:text-white truncate">
              {selectedMed.name_ar || selectedMed.name} ({t('inventory.col_stock')}: {selectedMed.current_stock})
            </span>
          </div>
        )}
        {medOpen && (
          <div className="absolute z-50 w-full mt-1 bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-600 rounded-lg shadow-lg max-h-56 overflow-y-auto">
            {filteredMeds.length === 0 ? (
              <div className="px-3 py-2 text-sm text-gray-400">{t('common.no_results') || 'No results'}</div>
            ) : filteredMeds.map(m => (
              <div key={m.id} onMouseDown={() => handleMedSelect(m)}
                className="px-3 py-2 text-sm cursor-pointer hover:bg-gray-100 dark:hover:bg-gray-700 flex justify-between">
                <span dir="rtl">{m.name_ar || m.name}</span>
                <span className="text-gray-400 text-xs">{t('inventory.col_stock')}: {m.current_stock}</span>
              </div>
            ))}
          </div>
        )}
      </div>
      <div>
        <label className="label">{t('inventory.adj_type')} *</label>
        <div className="grid grid-cols-3 gap-2">
          {[
            { value: 'add', label: t('inventory.type_add') },
            { value: 'remove', label: t('inventory.type_remove') },
            { value: 'correction', label: t('inventory.type_correction') },
          ].map(opt => (
            <button type="button" key={opt.value} onClick={() => set('type', opt.value)}
              className={`py-2 rounded-lg text-sm font-medium border-2 transition-colors ${form.type === opt.value ? 'border-primary-500 bg-primary-50 dark:bg-primary-900/20 text-primary-700 dark:text-primary-400' : 'border-gray-200 dark:border-gray-600 hover:border-gray-300'}`}>
              {opt.label}
            </button>
          ))}
        </div>
      </div>
      <div><label className="label">{t('inventory.col_quantity')} *</label><input type="number" min="1" value={form.quantity} onChange={e => set('quantity', e.target.value)} className="input" required /></div>
      <div>
        <label className="label">{t('inventory.reason')} *</label>
        <select value={form.reason} onChange={e => set('reason', e.target.value)} className="input" required>
          <option value="">{t('common.select')}</option>
          <option value="Damage/Breakage">{t('inventory.reasons.damage')}</option>
          <option value="Theft/Loss">{t('inventory.reasons.theft')}</option>
          <option value="Count correction">{t('inventory.reasons.correction')}</option>
          <option value="Transfer">{t('inventory.reasons.transfer')}</option>
          <option value="Other">{t('inventory.reasons.other')}</option>
        </select>
      </div>
      <div><label className="label">{t('common.notes')}</label><textarea value={form.notes} onChange={e => set('notes', e.target.value)} rows={2} className="input resize-none" /></div>
      <button type="submit" disabled={loading} className="btn-primary w-full">{loading ? t('common.processing') : t('inventory.apply_adj')}</button>
    </form>
  )
}

export default function InventoryPage() {
  const { t } = useTranslation()
  const { can } = useAuth()
  const { get, post, loading } = useApi()
  const pg = usePagination()
  const [searchParams] = useSearchParams()
  const [search, setSearch] = useState('')
  const [filter, setFilter] = useState(searchParams.get('filter') || '')
  const [rows, setRows] = useState([])
  const [medicines, setMedicines] = useState([])
  const [modal, setModal] = useState(null)
  const [saving, setSaving] = useState(false)

  const load = useCallback(() => {
    get('/api/inventory', { page: pg.page, per_page: pg.perPage, search, filter }).then(res => {
      setRows(res.data || []); pg.updateMeta(res.meta)
    })
  }, [pg.page, pg.perPage, search, filter])

  useEffect(() => { load() }, [load])

  useEffect(() => {
    if (modal === 'adjust') {
      get('/api/medicines', { per_page: 1000 }).then(res => setMedicines(res.data || []))
    }
  }, [modal])

  const handleAdjust = async (form) => {
    setSaving(true)
    try {
      await post('/api/inventory/adjust', form)
      toast.success(t('inventory.adjusted'))
      setModal(null); load()
    } catch {} finally { setSaving(false) }
  }

  const FILTERS = [
    { value: '', label: t('batches.filter_all') },
    { value: 'low_stock', label: t('inventory.filter_low') },
    { value: 'out_of_stock', label: t('inventory.filter_out') },
    { value: 'in_stock', label: t('inventory.filter_in') },
  ]

  return (
    <div className="p-6 space-y-5">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white">{t('inventory.title')}</h1>
          <p className="text-sm text-gray-500">{t('inventory.count', { count: pg.total })}</p>
        </div>
        {can('inventory.adjust') && (
          <button onClick={() => setModal('adjust')} className="btn-primary">
            <AdjustmentsHorizontalIcon className="w-4 h-4" /> {t('inventory.adjust')}
          </button>
        )}
      </div>

      <div className="card">
        <div className="p-4 border-b border-gray-100 dark:border-gray-700 flex flex-wrap gap-3 items-center">
          <SearchInput value={search} onChange={v => { setSearch(v); pg.setPage(1) }} placeholder={t('common.search')} className="max-w-sm" />
          <div className="flex gap-1 ms-auto">
            {FILTERS.map(f => (
              <button key={f.value} onClick={() => { setFilter(f.value); pg.setPage(1) }}
                className={`px-3 py-1.5 rounded-lg text-xs font-medium transition-colors ${filter === f.value ? 'bg-primary-600 text-white' : 'bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-300 hover:bg-gray-200'}`}>
                {f.label}
              </button>
            ))}
          </div>
        </div>

        {loading && !rows.length ? <TableSkeleton rows={6} cols={8} /> : (
          <div className="table-container">
            <table className="table">
              <thead>
                <tr>
                  <th>{t('inventory.col_medicine')}</th>
                  <th>SKU</th>
                  <th>{t('inventory.col_category')}</th>
                  <th>{t('inventory.col_pharmacist_price')}</th>
                  <th>{t('inventory.col_public_price')}</th>
                  <th>{t('inventory.col_stock')}</th>
                  <th>{t('inventory.col_min_stock')}</th>
                  <th>{t('inventory.col_value_pharmacist')}</th>
                  <th>{t('inventory.col_value_public')}</th>
                  <th>{t('common.status')}</th>
                </tr>
              </thead>
              <tbody>
                {rows.map(row => {
                  const s = stockStatus(row.current_stock, row.minimum_stock)
                  const value = parseFloat(row.current_stock) * parseFloat(row.purchase_price)
                  const valuePublic = parseFloat(row.current_stock) * parseFloat(row.public_price || row.selling_price)
                  return (
                    <tr key={row.id}>
                      <td>
                        <p className="font-medium text-gray-900 dark:text-white">{row.name}</p>
                        {row.name_ar && <p className="text-xs text-gray-400" dir="rtl">{row.name_ar}</p>}
                      </td>
                      <td className="font-mono text-xs text-gray-500">{row.sku}</td>
                      <td>{row.category_name || '—'}</td>
                      <td>{formatCurrency(row.purchase_price)}</td>
                      <td className="font-semibold">{formatCurrency(row.public_price || row.selling_price)}</td>
                      <td className="font-bold text-lg">{row.current_stock}</td>
                      <td className="text-gray-500">{row.minimum_stock}</td>
                      <td>{formatCurrency(value)}</td>
                      <td className="font-semibold text-green-600 dark:text-green-400">{formatCurrency(valuePublic)}</td>
                      <td>
                        <span className={`badge badge-${s.color}`}>{s.label}</span>
                      </td>
                    </tr>
                  )
                })}
                {!rows.length && !loading && <tr><td colSpan={10} className="text-center text-gray-400 py-12">{t('inventory.no_inventory')}</td></tr>}
              </tbody>
            </table>
          </div>
        )}
        <Pagination page={pg.page} totalPages={pg.totalPages} total={pg.total} perPage={pg.perPage} onPageChange={pg.setPage} />
      </div>

      <Modal open={modal === 'adjust'} onClose={() => setModal(null)} title={t('inventory.adjust')} size="md">
        <AdjustForm medicines={medicines} onSubmit={handleAdjust} loading={saving} />
      </Modal>
    </div>
  )
}
