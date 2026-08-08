import { useState, useEffect, useCallback } from 'react'
import { useTranslation } from 'react-i18next'
import {
  PlayIcon, StopIcon, ClockIcon, CurrencyDollarIcon,
  ArrowDownCircleIcon, ArrowUpCircleIcon, BanknotesIcon,
  ChartBarIcon, InformationCircleIcon,
} from '@heroicons/react/24/outline'
import { useApi, usePagination } from '../../hooks/useApi'
import { useAuth } from '../../context/AuthContext'
import { useShift } from '../../context/ShiftContext'
import Modal from '../../components/ui/Modal'
import Pagination from '../../components/ui/Pagination'
import { TableSkeleton } from '../../components/ui/Skeleton'
import { formatCurrency, formatDateTime } from '../../utils/format'
import toast from 'react-hot-toast'

// ── Helpers ────────────────────────────────────────────────────

function DiffBadge({ diff, t }) {
  if (diff == null) return <span className="text-gray-400">—</span>
  const abs = Math.abs(diff)
  if (abs < 0.001) return (
    <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-400">
      {t('shifts.balanced')}
    </span>
  )
  if (diff > 0) return (
    <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-400">
      +{formatCurrency(abs)} {t('shifts.over')}
    </span>
  )
  return (
    <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-400">
      -{formatCurrency(abs)} {t('shifts.short')}
    </span>
  )
}

// ── Shift Detail Modal ─────────────────────────────────────────
function ShiftDetail({ shift, t }) {
  if (!shift) return null
  const calc = shift.cash_breakdown || {}

  const openingCash  = parseFloat(shift.opening_cash || 0)
  const cashSales    = parseFloat(calc.cash_sales  ?? shift.cash_sales  ?? 0)
  const cardSales    = parseFloat(calc.card_sales  ?? shift.card_sales  ?? 0)
  const walletSales  = parseFloat(calc.wallet_sales ?? shift.wallet_sales ?? 0)
  const totalSales   = parseFloat(calc.total_sales ?? shift.sales_total ?? 0)
  const cashRefunds  = parseFloat(calc.cash_refunds ?? shift.cash_refunds ?? 0)
  const cashExpenses = parseFloat(calc.cash_expenses ?? shift.expenses_total ?? 0)
  const cashIn       = parseFloat(calc.cash_in ?? shift.cash_in_total ?? 0)
  const cashOut      = parseFloat(calc.cash_out ?? shift.cash_out_total ?? 0)
  const expectedCash = parseFloat(calc.expected_cash ?? shift.expected_cash ?? 0)
  const countedCash  = parseFloat(shift.counted_cash ?? shift.closing_cash ?? 0)
  const difference   = shift.status === 'closed' ? (shift.difference ?? (countedCash - expectedCash)) : null

  return (
    <div className="space-y-5">
      {/* Header row */}
      <div className="grid grid-cols-2 gap-3">
        {[
          [t('shifts.opened_at'),   formatDateTime(shift.opened_at)],
          [t('shifts.closed_at'),   shift.closed_at ? formatDateTime(shift.closed_at) : '—'],
          [t('shifts.opened_by'),   shift.opened_by_name],
          [t('shifts.opening_cash'),formatCurrency(openingCash)],
        ].map(([label, value]) => (
          <div key={label} className="bg-gray-50 dark:bg-gray-700 rounded-lg p-3">
            <p className="text-xs text-gray-500 dark:text-gray-400 mb-0.5">{label}</p>
            <p className="text-sm font-semibold text-gray-900 dark:text-white">{value}</p>
          </div>
        ))}
      </div>

      {/* Sales Breakdown */}
      <div>
        <p className="text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wide mb-2">{t('shifts.sales_breakdown')}</p>
        <div className="grid grid-cols-2 gap-2">
          {[
            [t('shifts.cash_sales'),   cashSales,   'text-green-600 dark:text-green-400'],
            [t('shifts.card_sales'),   cardSales,   'text-blue-600 dark:text-blue-400'],
            [t('shifts.wallet_sales'), walletSales, 'text-purple-600 dark:text-purple-400'],
            [t('shifts.total_sales'),  totalSales,  'text-gray-900 dark:text-white font-bold'],
          ].map(([label, val, cls]) => (
            <div key={label} className="bg-gray-50 dark:bg-gray-700 rounded-lg p-3">
              <p className="text-xs text-gray-500 dark:text-gray-400 mb-0.5">{label}</p>
              <p className={`text-sm font-semibold ${cls}`}>{formatCurrency(val)}</p>
            </div>
          ))}
        </div>
      </div>

      {/* Drawer Summary */}
      <div>
        <p className="text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wide mb-2">{t('shifts.drawer_summary')}</p>
        <div className="rounded-xl border border-gray-200 dark:border-gray-600 overflow-hidden">
          {[
            { label: t('shifts.opening_cash'),  value: formatCurrency(openingCash),  sign: null,  cls: '' },
            { label: '+ ' + t('shifts.cash_sales'), value: formatCurrency(cashSales), sign: '+', cls: 'text-green-600 dark:text-green-400' },
            { label: '+ ' + t('shifts.cash_in'),  value: formatCurrency(cashIn),   sign: '+', cls: 'text-green-600 dark:text-green-400' },
            { label: '− ' + t('shifts.cash_refunds'),  value: formatCurrency(cashRefunds),  sign: '-', cls: 'text-red-600 dark:text-red-400' },
            { label: '− ' + t('shifts.expenses_total'), value: formatCurrency(cashExpenses), sign: '-', cls: 'text-red-600 dark:text-red-400' },
            { label: '− ' + t('shifts.cash_out'), value: formatCurrency(cashOut),  sign: '-', cls: 'text-red-600 dark:text-red-400' },
          ].map(row => (
            <div key={row.label} className="flex justify-between items-center px-4 py-2.5 border-b border-gray-100 dark:border-gray-700 last:border-b-0">
              <span className="text-sm text-gray-600 dark:text-gray-300">{row.label}</span>
              <span className={`text-sm font-medium ${row.cls || 'text-gray-900 dark:text-white'}`}>{row.value}</span>
            </div>
          ))}
          <div className="flex justify-between items-center px-4 py-3 bg-blue-50 dark:bg-blue-900/20 border-t-2 border-blue-200 dark:border-blue-700">
            <span className="text-sm font-bold text-blue-800 dark:text-blue-300">{t('shifts.expected_cash')}</span>
            <span className="text-base font-bold text-blue-800 dark:text-blue-300">{formatCurrency(expectedCash)}</span>
          </div>
          {shift.status === 'closed' && (
            <>
              <div className="flex justify-between items-center px-4 py-2.5 border-t border-gray-100 dark:border-gray-700">
                <span className="text-sm text-gray-600 dark:text-gray-300">{t('shifts.counted_cash_label')}</span>
                <span className="text-sm font-semibold text-gray-900 dark:text-white">{formatCurrency(countedCash)}</span>
              </div>
              <div className="flex justify-between items-center px-4 py-3 bg-gray-50 dark:bg-gray-700">
                <span className="text-sm font-bold text-gray-700 dark:text-gray-200">{t('shifts.difference')}</span>
                <DiffBadge diff={difference} t={t} />
              </div>
            </>
          )}
        </div>
      </div>

      {/* Cash Movements */}
      {shift.cash_movements?.length > 0 && (
        <div>
          <p className="text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wide mb-2">{t('shifts.cash_movements')}</p>
          <div className="space-y-1">
            {shift.cash_movements.map(m => (
              <div key={m.id} className="flex items-center justify-between px-3 py-2 rounded-lg bg-gray-50 dark:bg-gray-700">
                <div className="flex items-center gap-2">
                  {m.type === 'cash_in'
                    ? <ArrowDownCircleIcon className="w-4 h-4 text-green-500" />
                    : <ArrowUpCircleIcon className="w-4 h-4 text-red-500" />}
                  <span className="text-xs text-gray-600 dark:text-gray-300">{m.reason || (m.type === 'cash_in' ? t('shifts.cash_in') : t('shifts.cash_out'))}</span>
                </div>
                <span className={`text-xs font-semibold ${m.type === 'cash_in' ? 'text-green-600 dark:text-green-400' : 'text-red-600 dark:text-red-400'}`}>
                  {m.type === 'cash_in' ? '+' : '−'}{formatCurrency(m.amount)}
                </span>
              </div>
            ))}
          </div>
        </div>
      )}

      {shift.notes && (
        <div className="bg-blue-50 dark:bg-blue-900/20 rounded-lg p-3">
          <p className="text-xs text-blue-600 dark:text-blue-400 font-medium mb-1">{t('common.notes')}</p>
          <p className="text-sm text-gray-700 dark:text-gray-300">{shift.notes}</p>
        </div>
      )}
    </div>
  )
}

// ── Cash Movement Modal ────────────────────────────────────────
function CashMovementModal({ type, onClose, onSaved, post }) {
  const { t } = useTranslation()
  const [form, setForm]         = useState({ amount: '', reason: '' })
  const [submitting, setSubmitting] = useState(false)

  const isIn = type === 'cash_in'

  const handleSubmit = async (e) => {
    e.preventDefault()
    if (!form.amount || parseFloat(form.amount) <= 0) return
    setSubmitting(true)
    const fd = new FormData()
    fd.append('amount', form.amount)
    fd.append('reason', form.reason)
    const res = await post(`/api/shifts/${isIn ? 'cash-in' : 'cash-out'}`, fd)
    setSubmitting(false)
    if (res?.ok !== false) {
      toast.success(t('shifts.cash_movement_added'))
      onSaved(res?.data)
    }
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <div className={`flex items-start gap-3 p-3 rounded-lg ${isIn ? 'bg-green-50 dark:bg-green-900/20' : 'bg-red-50 dark:bg-red-900/20'}`}>
        {isIn
          ? <ArrowDownCircleIcon className="w-5 h-5 text-green-600 dark:text-green-400 mt-0.5 shrink-0" />
          : <ArrowUpCircleIcon className="w-5 h-5 text-red-600 dark:text-red-400 mt-0.5 shrink-0" />}
        <p className={`text-xs leading-relaxed ${isIn ? 'text-green-700 dark:text-green-300' : 'text-red-700 dark:text-red-300'}`}>
          {isIn ? t('shifts.cash_in_hint') : t('shifts.cash_out_hint')}
        </p>
      </div>

      <div>
        <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">{t('expenses.amount')} *</label>
        <input type="number" step="0.001" min="0.001" value={form.amount} required
          onChange={e => setForm(f => ({ ...f, amount: e.target.value }))}
          className="w-full border border-gray-300 dark:border-gray-600 rounded-lg px-3 py-2 text-sm bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-primary-500" />
      </div>

      <div>
        <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">{t('shifts.reason')}</label>
        <input type="text" value={form.reason}
          onChange={e => setForm(f => ({ ...f, reason: e.target.value }))}
          placeholder={t('common.optional')}
          className="w-full border border-gray-300 dark:border-gray-600 rounded-lg px-3 py-2 text-sm bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-primary-500" />
      </div>

      <div className="flex justify-end gap-2 pt-1">
        <button type="button" onClick={onClose}
          className="px-4 py-2 text-sm text-gray-600 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700 rounded-lg">{t('common.cancel')}</button>
        <button type="submit" disabled={submitting}
          className={`px-4 py-2 text-sm text-white rounded-lg disabled:opacity-50 ${isIn ? 'bg-green-600 hover:bg-green-700' : 'bg-red-600 hover:bg-red-700'}`}>
          {submitting ? t('common.saving') : (isIn ? t('shifts.cash_in') : t('shifts.cash_out'))}
        </button>
      </div>
    </form>
  )
}

// ── Main Page ──────────────────────────────────────────────────
export default function ShiftsPage() {
  const { t } = useTranslation()
  const { can } = useAuth()
  const { get, post, loading } = useApi()
  const { refreshShift } = useShift()
  const pg = usePagination()

  const [rows, setRows]         = useState([])
  const [current, setCurrent]   = useState(null)

  const [showOpen, setShowOpen]   = useState(false)
  const [showClose, setShowClose] = useState(false)
  const [viewShift, setViewShift] = useState(null)
  const [cashMovType, setCashMovType] = useState(null) // 'cash_in' | 'cash_out' | null

  const [openForm, setOpenForm]   = useState({ opening_cash: '', notes: '' })
  const [closeForm, setCloseForm] = useState({ counted_cash: '', notes: '' })
  const [submitting, setSubmitting] = useState(false)

  const loadCurrent = useCallback(() => {
    get('/api/shifts/current').then(r => setCurrent(r.data || null)).catch(() => setCurrent(null))
  }, [])

  const load = useCallback(() => {
    get(`/api/shifts?page=${pg.page}&per_page=${pg.perPage}`).then(r => {
      setRows(r.data || [])
      pg.updateMeta(r.meta)
    }).catch(() => {})
  }, [pg.page, pg.perPage])

  useEffect(() => { loadCurrent() }, [loadCurrent])
  useEffect(() => { load() }, [load])

  const handleOpen = async (e) => {
    e.preventDefault()
    setSubmitting(true)
    const fd = new FormData()
    fd.append('opening_cash', openForm.opening_cash || '0')
    fd.append('notes', openForm.notes)
    const res = await post('/api/shifts/open', fd)
    setSubmitting(false)
    if (res?.ok !== false) {
      toast.success(t('shifts.opened_success'))
      setShowOpen(false)
      setOpenForm({ opening_cash: '', notes: '' })
      loadCurrent()
      load()
      refreshShift()
    }
  }

  const handleClose = async (e) => {
    e.preventDefault()
    if (!current) return
    setSubmitting(true)
    const fd = new FormData()
    fd.append('counted_cash', closeForm.counted_cash)
    fd.append('notes', closeForm.notes)
    const res = await post(`/api/shifts/${current.id}/close`, fd)
    setSubmitting(false)
    if (res?.ok !== false) {
      toast.success(t('shifts.closed_success'))
      setShowClose(false)
      setCloseForm({ counted_cash: '', notes: '' })
      loadCurrent()
      load()
      refreshShift()
    }
  }

  const handleCashMovSaved = (data) => {
    setCashMovType(null)
    if (data?.expected_cash !== undefined) {
      setCurrent(prev => prev ? { ...prev, live_expected_cash: data.expected_cash } : prev)
    }
    loadCurrent()
  }

  const statusBadge = (status) => status === 'open'
    ? 'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-400'
    : 'bg-gray-100 text-gray-700 dark:bg-gray-700 dark:text-gray-300'

  // Live numbers from current shift
  const liveExpected = current?.live_expected_cash ?? 0
  const liveCashSales = current?.live_cash_sales ?? 0
  const liveSalesTotal = current?.live_total_sales ?? 0
  const liveCashExpenses = current?.live_cash_expenses ?? 0

  return (
    <div className="p-6 space-y-5">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white">{t('shifts.title')}</h1>
          <p className="text-sm text-gray-500 mt-0.5">{t('shifts.subtitle')}</p>
        </div>
        {can('shifts.manage') && (
          <div className="flex gap-2">
            {!current ? (
              <button onClick={() => setShowOpen(true)}
                className="flex items-center gap-1.5 px-4 py-2 bg-green-600 text-white text-sm font-medium rounded-lg hover:bg-green-700">
                <PlayIcon className="w-4 h-4" />
                {t('shifts.open_shift')}
              </button>
            ) : (
              <button onClick={() => setShowClose(true)}
                className="flex items-center gap-1.5 px-4 py-2 bg-red-600 text-white text-sm font-medium rounded-lg hover:bg-red-700">
                <StopIcon className="w-4 h-4" />
                {t('shifts.close_shift')}
              </button>
            )}
          </div>
        )}
      </div>

      {/* Active shift panel */}
      {current && (
        <div className="bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800 rounded-xl p-4 space-y-4">
          <div className="flex items-center justify-between flex-wrap gap-3">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 bg-green-100 dark:bg-green-900/40 rounded-lg flex items-center justify-center">
                <ClockIcon className="w-5 h-5 text-green-600 dark:text-green-400" />
              </div>
              <div>
                <p className="text-sm font-bold text-green-800 dark:text-green-300">{t('shifts.active_shift')}</p>
                <p className="text-xs text-green-600 dark:text-green-400">{formatDateTime(current.opened_at)}</p>
              </div>
            </div>

            {/* Cash In / Cash Out buttons */}
            {can('shifts.cash_movement') && (
              <div className="flex gap-2">
                <button onClick={() => setCashMovType('cash_in')}
                  className="flex items-center gap-1.5 px-3 py-1.5 bg-green-600 text-white text-xs font-medium rounded-lg hover:bg-green-700">
                  <ArrowDownCircleIcon className="w-3.5 h-3.5" />
                  {t('shifts.cash_in')}
                </button>
                <button onClick={() => setCashMovType('cash_out')}
                  className="flex items-center gap-1.5 px-3 py-1.5 bg-orange-500 text-white text-xs font-medium rounded-lg hover:bg-orange-600">
                  <ArrowUpCircleIcon className="w-3.5 h-3.5" />
                  {t('shifts.cash_out')}
                </button>
              </div>
            )}
          </div>

          {/* Live stats */}
          <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
            {[
              [t('shifts.opening_cash'),  current.opening_cash, 'text-gray-700 dark:text-gray-300'],
              [t('shifts.cash_sales'),    liveCashSales,         'text-green-700 dark:text-green-300'],
              [t('shifts.cash_expenses'), liveCashExpenses,      'text-red-600 dark:text-red-400'],
              [t('shifts.expected_cash'), liveExpected,          'text-blue-700 dark:text-blue-300'],
            ].map(([label, val, cls]) => (
              <div key={label} className="bg-white/60 dark:bg-gray-800/60 rounded-lg p-3">
                <p className="text-xs text-green-600 dark:text-green-400 mb-0.5">{label}</p>
                <p className={`text-sm font-bold ${cls}`}>{formatCurrency(val)}</p>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Shifts Table */}
      <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-100 dark:border-gray-700 overflow-hidden">
        {loading && !rows.length ? (
          <TableSkeleton rows={8} cols={7} />
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-gray-100 dark:border-gray-700 bg-gray-50 dark:bg-gray-700/50">
                  {['#', t('shifts.opened_by'), t('shifts.opened_at'), t('shifts.closed_at'),
                    t('shifts.expected_cash'), t('shifts.counted_cash'), t('shifts.difference'), t('common.status'), ''].map((h, i) => (
                    <th key={i} className="text-start px-4 py-3 text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wide">{h}</th>
                  ))}
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-50 dark:divide-gray-700">
                {!rows.length ? (
                  <tr><td colSpan={9} className="px-4 py-12 text-center text-sm text-gray-400">{t('common.no_data')}</td></tr>
                ) : rows.map(row => (
                  <tr key={row.id} className="hover:bg-gray-50 dark:hover:bg-gray-700/30 transition-colors cursor-pointer"
                    onClick={() => {
                      get(`/api/shifts/${row.id}`).then(r => setViewShift(r.data)).catch(() => setViewShift(row))
                    }}>
                    <td className="px-4 py-3 font-mono text-xs text-gray-500 dark:text-gray-400">#{row.id}</td>
                    <td className="px-4 py-3 text-gray-900 dark:text-white font-medium">{row.opened_by_name}</td>
                    <td className="px-4 py-3 text-gray-600 dark:text-gray-300">{formatDateTime(row.opened_at)}</td>
                    <td className="px-4 py-3 text-gray-500 dark:text-gray-400">{row.closed_at ? formatDateTime(row.closed_at) : '—'}</td>
                    <td className="px-4 py-3 font-semibold text-blue-600 dark:text-blue-400">{row.expected_cash != null ? formatCurrency(row.expected_cash) : '—'}</td>
                    <td className="px-4 py-3 font-semibold text-gray-700 dark:text-gray-300">{row.counted_cash != null ? formatCurrency(row.counted_cash) : '—'}</td>
                    <td className="px-4 py-3"><DiffBadge diff={row.difference} t={t} /></td>
                    <td className="px-4 py-3">
                      <span className={`inline-flex px-2 py-0.5 rounded-full text-xs font-medium ${statusBadge(row.status)}`}>
                        {row.status === 'open' ? t('shifts.status_open') : t('shifts.status_closed')}
                      </span>
                    </td>
                    <td className="px-4 py-3" onClick={e => e.stopPropagation()}></td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
        {pg.total > pg.perPage && (
          <div className="px-4 py-3 border-t border-gray-100 dark:border-gray-700">
            <Pagination page={pg.page} perPage={pg.perPage} total={pg.total} onPageChange={pg.setPage} />
          </div>
        )}
      </div>

      {/* Open shift modal */}
      <Modal open={showOpen} onClose={() => setShowOpen(false)} title={t('shifts.open_shift')} size="sm">
        <form onSubmit={handleOpen} className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">{t('shifts.opening_cash')}</label>
            <input type="number" step="0.001" min="0" value={openForm.opening_cash}
              onChange={e => setOpenForm(f => ({ ...f, opening_cash: e.target.value }))} required
              placeholder="0.000"
              className="w-full border border-gray-300 dark:border-gray-600 rounded-lg px-3 py-2 text-sm bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-primary-500" />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">{t('common.notes')}</label>
            <textarea rows={2} value={openForm.notes} onChange={e => setOpenForm(f => ({ ...f, notes: e.target.value }))}
              className="w-full border border-gray-300 dark:border-gray-600 rounded-lg px-3 py-2 text-sm bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-primary-500 resize-none" />
          </div>
          <div className="flex justify-end gap-2 pt-1">
            <button type="button" onClick={() => setShowOpen(false)}
              className="px-4 py-2 text-sm text-gray-600 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700 rounded-lg">{t('common.cancel')}</button>
            <button type="submit" disabled={submitting}
              className="px-4 py-2 text-sm bg-green-600 text-white rounded-lg hover:bg-green-700 disabled:opacity-50">
              {submitting ? t('common.saving') : t('shifts.open_shift')}
            </button>
          </div>
        </form>
      </Modal>

      {/* Close shift modal */}
      <Modal open={showClose} onClose={() => setShowClose(false)} title={t('shifts.close_shift')} size="sm">
        {current && (
          <form onSubmit={handleClose} className="space-y-4">
            <div className="flex items-start gap-2 text-xs text-gray-500 dark:text-gray-400 bg-blue-50 dark:bg-blue-900/20 rounded-lg px-3 py-2">
              <InformationCircleIcon className="w-4 h-4 text-blue-500 shrink-0 mt-0.5" />
              {t('shifts.close_shift_hint')}
            </div>

            {/* Live expected cash preview */}
            <div className="bg-gray-50 dark:bg-gray-700 rounded-lg p-3 space-y-2 text-sm">
              {[
                [t('shifts.opening_cash'),  current.opening_cash,   ''],
                [t('shifts.cash_sales'),    liveCashSales,           'text-green-600 dark:text-green-400'],
                [t('shifts.cash_expenses'), liveCashExpenses,        'text-red-600 dark:text-red-400'],
                [t('shifts.expected_cash'), liveExpected,            'text-blue-700 dark:text-blue-300 font-bold'],
              ].map(([label, val, cls]) => (
                <div key={label} className="flex justify-between">
                  <span className="text-gray-500 dark:text-gray-400">{label}</span>
                  <span className={`font-semibold ${cls || 'text-gray-900 dark:text-white'}`}>{formatCurrency(val)}</span>
                </div>
              ))}
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">{t('shifts.counted_cash')} *</label>
              <input type="number" step="0.001" min="0" value={closeForm.counted_cash} required
                onChange={e => setCloseForm(f => ({ ...f, counted_cash: e.target.value }))}
                placeholder="0.000"
                className="w-full border border-gray-300 dark:border-gray-600 rounded-lg px-3 py-2 text-sm bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-primary-500" />
              {closeForm.counted_cash !== '' && (
                <p className="text-xs mt-1">
                  {(() => {
                    const diff = parseFloat(closeForm.counted_cash) - liveExpected
                    if (Math.abs(diff) < 0.001) return <span className="text-green-600">{t('shifts.balanced')}</span>
                    if (diff > 0) return <span className="text-blue-600">{t('shifts.over')}: +{formatCurrency(Math.abs(diff))}</span>
                    return <span className="text-red-600">{t('shifts.short')}: -{formatCurrency(Math.abs(diff))}</span>
                  })()}
                </p>
              )}
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">{t('common.notes')}</label>
              <textarea rows={2} value={closeForm.notes} onChange={e => setCloseForm(f => ({ ...f, notes: e.target.value }))}
                className="w-full border border-gray-300 dark:border-gray-600 rounded-lg px-3 py-2 text-sm bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-primary-500 resize-none" />
            </div>

            <div className="flex justify-end gap-2 pt-1">
              <button type="button" onClick={() => setShowClose(false)}
                className="px-4 py-2 text-sm text-gray-600 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700 rounded-lg">{t('common.cancel')}</button>
              <button type="submit" disabled={submitting}
                className="px-4 py-2 text-sm bg-red-600 text-white rounded-lg hover:bg-red-700 disabled:opacity-50">
                {submitting ? t('common.saving') : t('shifts.close_shift')}
              </button>
            </div>
          </form>
        )}
      </Modal>

      {/* Cash In / Cash Out modals */}
      <Modal
        open={cashMovType === 'cash_in'}
        onClose={() => setCashMovType(null)}
        title={t('shifts.cash_in_title')}
        size="sm">
        <CashMovementModal type="cash_in" post={post} onClose={() => setCashMovType(null)} onSaved={handleCashMovSaved} />
      </Modal>
      <Modal
        open={cashMovType === 'cash_out'}
        onClose={() => setCashMovType(null)}
        title={t('shifts.cash_out_title')}
        size="sm">
        <CashMovementModal type="cash_out" post={post} onClose={() => setCashMovType(null)} onSaved={handleCashMovSaved} />
      </Modal>

      {/* View shift detail modal */}
      <Modal
        open={!!viewShift}
        onClose={() => setViewShift(null)}
        title={`${t('shifts.shift')} #${viewShift?.id}`}
        size="md">
        <ShiftDetail shift={viewShift} t={t} />
      </Modal>
    </div>
  )
}
