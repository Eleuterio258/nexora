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

    fun nowForApi(): String = apiFormatter.format(Date())

    /** Data de hoje no formato YYYY-MM-DD (campo `data DATE` do ERP, ex.: justificações). */
    fun todayForApi(): String = apiDateFormatter.format(Date())

    fun formatDateTime(value: String): String {
        return parse(value)?.let { dateTimeFormatter.format(it) } ?: value
    }

    fun formatDate(value: String): String {
        return parse(value)?.let { dateFormatter.format(it) } ?: value
    }

    private fun parse(value: String): Date? {
        return try {
            apiFormatter.parse(value)
        } catch (_: ParseException) {
            null
        }
    }
}
