package fr.sarrazi.asso

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.google.firebase.messaging.FirebaseMessaging

class BootCompleteReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        if (intent?.action in listOf(
                Intent.ACTION_BOOT_COMPLETED,
                "android.intent.action.LOCKED_BOOT_COMPLETED",
                "com.htc.intent.action.QUICKBOOT_POWERON"
            )) {
            FirebaseMessaging.getInstance().isAutoInitEnabled = true
        }
    }
}