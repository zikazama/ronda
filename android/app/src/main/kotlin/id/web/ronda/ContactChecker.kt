package id.web.ronda

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.net.Uri
import android.provider.ContactsContract

/** Memeriksa apakah pengirim adalah kontak tersimpan. Tanpa izin => dianggap bukan kontak. */
object ContactChecker {

    private val NUMBER_LIKE = Regex("^\\+?[\\d\\s\\-()]{8,}$")

    fun isSavedContact(context: Context, sender: String): Boolean {
        if (context.checkSelfPermission(Manifest.permission.READ_CONTACTS)
            != PackageManager.PERMISSION_GRANTED
        ) return false

        return try {
            val s = sender.trim()
            if (NUMBER_LIKE.matches(s)) byNumber(context, s) else byName(context, s)
        } catch (e: Exception) {
            false
        }
    }

    private fun byNumber(context: Context, number: String): Boolean {
        val uri = Uri.withAppendedPath(
            ContactsContract.PhoneLookup.CONTENT_FILTER_URI, Uri.encode(number)
        )
        context.contentResolver.query(
            uri, arrayOf(ContactsContract.PhoneLookup._ID), null, null, null
        )?.use { return it.count > 0 }
        return false
    }

    private fun byName(context: Context, name: String): Boolean {
        context.contentResolver.query(
            ContactsContract.Contacts.CONTENT_URI,
            arrayOf(ContactsContract.Contacts._ID),
            "${ContactsContract.Contacts.DISPLAY_NAME} = ?",
            arrayOf(name),
            null
        )?.use { return it.count > 0 }
        return false
    }
}
