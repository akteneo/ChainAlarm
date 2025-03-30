package com.example.chainalarm

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat

class AlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val chainId = intent.getIntExtra("chainId", -1)
        val alarmIndex = intent.getIntExtra("alarmIndex", -1)
        
        val channelId = "chain_alarm_channel"
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel(
                channelId,
                "Chain Alarms",
                NotificationManager.IMPORTANCE_HIGH
            ).apply { notificationManager.createNotificationChannel(this) }
        }

        val snoozeIntent = Intent(context, MainActivity::class.java).apply {
            putExtra("snooze", true)
            putExtra("chainId", chainId)
            putExtra("alarmIndex", alarmIndex)
        }
        
        val pendingIntent = PendingIntent.getActivity(
            context,
            0,
            snoozeIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        NotificationCompat.Builder(context, channelId)
            .setContentTitle("Цепочный будильник")
            .setContentText("Пора просыпаться!")
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .addAction(R.drawable.ic_snooze, "Отложить", pendingIntent)
            .build()
            .also { notificationManager.notify(chainId * 100 + alarmIndex, it) }
    }
}
