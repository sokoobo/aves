package deckers.thibault.aves.model.provider

import android.content.Context
import android.net.Uri
import android.provider.MediaStore
import android.provider.OpenableColumns
import android.util.Log
import deckers.thibault.aves.metadata.Metadata
import deckers.thibault.aves.metadata.metadataextractor.Helper
import deckers.thibault.aves.model.FieldMap
import deckers.thibault.aves.model.SourceEntry
import deckers.thibault.aves.utils.LogUtils
import deckers.thibault.aves.utils.MimeTypes
import deckers.thibault.aves.utils.StorageUtils

internal class ContentImageProvider : ImageProvider() {
    override fun fetchSingle(context: Context, uri: Uri, sourceMimeType: String?, callback: ImageOpCallback) {
        // source MIME type may be incorrect, so we get a second opinion if possible
        var extractorMimeType: String? = null
        try {
            val safeUri = Uri.fromFile(Metadata.createPreviewFile(context, uri))
            StorageUtils.openInputStream(context, safeUri)?.use { input ->
                // `metadata-extractor` is the most reliable, except for `tiff` (false positives, false negatives)
                // cf https://github.com/drewnoakes/metadata-extractor/issues/296
                Helper.readMimeType(input)?.takeIf { it != MimeTypes.TIFF }?.let {
                    extractorMimeType = it
                    if (extractorMimeType != sourceMimeType) {
                        Log.d(LOG_TAG, "source MIME type is $sourceMimeType but extracted MIME type is $extractorMimeType for uri=$uri")
                    }
                }
            }
        } catch (e: Exception) {
            Log.w(LOG_TAG, "failed to get MIME type by metadata-extractor for uri=$uri", e)
        } catch (e: NoClassDefFoundError) {
            Log.w(LOG_TAG, "failed to get MIME type by metadata-extractor for uri=$uri", e)
        } catch (e: AssertionError) {
            Log.w(LOG_TAG, "failed to get MIME type by metadata-extractor for uri=$uri", e)
        }

        val mimeType = extractorMimeType ?: sourceMimeType
        if (mimeType == null) {
            callback.onFailure(Exception("MIME type is null for uri=$uri"))
            return
        }

        val fields: FieldMap = hashMapOf(
            "uri" to uri.toString(),
            "sourceMimeType" to mimeType,
        )
        try {
            // some providers do not provide the mandatory `OpenableColumns`
            // and the query fails when compiling a projection specifying them
            // e.g. `content://mms/part/[id]` on Android KitKat
            val cursor = context.contentResolver.query(uri, null, null, null, null)
            if (cursor != null && cursor.moveToFirst()) {
                cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME).let { if (it != -1) fields["title"] = cursor.getString(it) }
                cursor.getColumnIndex(OpenableColumns.SIZE).let { if (it != -1) fields["sizeBytes"] = cursor.getLong(it) }
                cursor.getColumnIndex(MediaStore.MediaColumns.DATA).let { if (it != -1) fields["path"] = cursor.getString(it) }
                cursor.close()
            }
        } catch (e: Exception) {
            callback.onFailure(e)
            return
        }

        val entry = SourceEntry(fields).fillPreCatalogMetadata(context)
        if (entry.isSized || entry.isSvg || entry.isVideo) {
            callback.onSuccess(entry.toMap())
        } else {
            callback.onFailure(Exception("entry has no size"))
        }
    }

    companion object {
        private val LOG_TAG = LogUtils.createTag<ContentImageProvider>()
    }
}