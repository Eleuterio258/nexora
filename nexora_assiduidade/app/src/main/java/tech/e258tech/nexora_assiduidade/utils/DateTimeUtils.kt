package tech.e258tech.nexora_assiduidade.utils

import java.text.ParseException
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone

object DateTimeUtils {

    private val apiFormatter: SimpleDateFormat = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ssXXX", Locale.getDefault()).apply {
        timeZone = TimeZone.getDefault()
    }
    private val apiDateFormatter: SimpleDateFormat = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault())
    private val dateFormatter: SimpleDateFormat = SimpleDateFormat("dd/MM/yyyy", Locale.getDefault())
    private val dateTimeFormatter: SimpleDateFormat = SimpleDateFormat("dd/MM/yyyy HH:mm", Locale.getDefault())
    private val localDateTimeFormatter: SimpleDateFormat = SimpleDateFormat("yyyy-MM-dd'T'HH:mm", Locale.getDefault())

    fun nowForApi(): String = apiFormatter.format(Date())

    /** Data de hoje no formato YYYY-MM-DD (campo `data DATE` do ERP, ex.: justificações). */
    fun todayForApi(): String = apiDateFormatter.format(Date())

    fun formatDateTime(value: String): String {
        return parse(value)?.let { dateTimeFormatter.format(it) } ?: value
    }

    fun formatDate(value: String): String {
        return parse(value)?.let { dateFormatter.format(it) } ?: value
    }

    /** Formata um campo `DATE` puro (ex.: `data_fecho_prevista` do CRM, já vem
     * como "YYYY-MM-DD" formatado pelo ERP via to_char) — diferente de
     * [formatDate], que espera datetime ISO com offset. */
    fun formatDateOnly(value: String): String {
        return try {
            dateFormatter.format(apiDateFormatter.parse(value) ?: return value)
        } catch (_: ParseException) {
            value
        }
    }

    /** Constrói "YYYY-MM-DD" a partir dos campos de um DatePickerDialog (mês 0-based). */
    fun dateOnlyForApi(year: Int, month: Int, day: Int): String {
        val cal = java.util.Calendar.getInstance()
        cal.set(year, month, day)
        return apiDateFormatter.format(cal.time)
    }

    /** Segunda-feira da semana corrente (semana começa na segunda, convenção PT). */
    fun startOfWeek(): java.util.Calendar {
        val cal = java.util.Calendar.getInstance()
        val diasDesdeSegunda = (cal.get(java.util.Calendar.DAY_OF_WEEK) - java.util.Calendar.MONDAY + 7) % 7
        cal.add(java.util.Calendar.DAY_OF_MONTH, -diasDesdeSegunda)
        return cal
    }

    fun formatApiDate(cal: java.util.Calendar): String = apiDateFormatter.format(cal.time)

    /** Constrói "YYYY-MM-DDTHH:MM" (formato alternativo aceite pelo ERP para
     * `data_atividade` do CRM, equivalente a <input type=datetime-local>). */
    fun localDateTimeForApi(year: Int, month: Int, day: Int, hour: Int, minute: Int): String {
        val cal = java.util.Calendar.getInstance()
        cal.set(year, month, day, hour, minute)
        return localDateTimeFormatter.format(cal.time)
    }

    private fun parse(value: String): Date? {
        return try {
            apiFormatter.parse(value)
        } catch (_: ParseException) {
            null
        }
    }
}
