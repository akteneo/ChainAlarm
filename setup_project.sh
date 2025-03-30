#!/bin/bash

# Создаем структуру папок
mkdir -p app/src/main/java/com/example/chainalarm
mkdir -p app/src/main/res/layout
mkdir -p .github/workflows

# Создаем файлы реализации
cat > app/src/main/java/com/example/chainalarm/AlarmChain.kt << 'EOL'
package com.example.chainalarm

data class AlarmChain(
    val id: Int,
    val originalTimes: List<Long>,
    var currentTimes: List<Long>,
    val interval: Long = 30 * 60 * 1000
)
EOL

cat > app/src/main/java/com/example/chainalarm/AlarmReceiver.kt << 'EOL'
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
EOL

# Обновляем макет активности
cat > app/src/main/res/layout/activity_main.xml << 'EOL'
<?xml version="1.0" encoding="utf-8"?>
<androidx.coordinatorlayout.widget.CoordinatorLayout
    xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    android:layout_width="match_parent"
    android:layout_height="match_parent">

    <androidx.recyclerview.widget.RecyclerView
        android:id="@+id/chainsRecyclerView"
        android:layout_width="match_parent"
        android:layout_height="match_parent"
        app:layoutManager="androidx.recyclerview.widget.LinearLayoutManager"/>

    <com.google.android.material.floatingactionbutton.FloatingActionButton
        android:id="@+id/fab"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:layout_gravity="bottom|end"
        android:layout_margin="16dp"
        android:src="@android:drawable/ic_input_add"/>

</androidx.coordinatorlayout.widget.CoordinatorLayout>
EOL

# Обновляем манифест
cat > app/src/main/AndroidManifest.xml << 'EOL'
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools"
    package="com.example.chainalarm">

    <uses-permission android:name="android.permission.SET_ALARM" />
    <uses-permission android:name="android.permission.WAKE_LOCK" />
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

    <application
        android:allowBackup="true"
        android:icon="@mipmap/ic_launcher"
        android:label="@string/app_name"
        android:roundIcon="@mipmap/ic_launcher_round"
        android:supportsRtl="true"
        android:theme="@style/Theme.ChainAlarm">
        
        <activity
            android:name=".MainActivity"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>

        <receiver
            android:name=".AlarmReceiver"
            android:exported="false" />
            
    </application>
</manifest>
EOL

# Обновляем MainActivity
cat > app/src/main/java/com/example/chainalarm/MainActivity.kt << 'EOL'
package com.example.chainalarm

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import androidx.appcompat.app.AppCompatActivity
import android.os.Bundle
import android.widget.Toast
import com.google.android.material.floatingactionbutton.FloatingActionButton

class MainActivity : AppCompatActivity() {
    private lateinit var alarmManager: AlarmManager
    private val alarmChains = mutableListOf<AlarmChain>()
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        
        alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        handleIntent()
        setupUI()
    }
    
    private fun handleIntent() {
        intent?.takeIf { it.getBooleanExtra("snooze", false) }?.let {
            onSnooze(it.getIntExtra("chainId", -1), it.getIntExtra("alarmIndex", -1))
            Toast.makeText(this, "Будильник отложен на 30 минут", Toast.LENGTH_SHORT).show()
        }
    }
    
    private fun setupUI() {
        findViewById<FloatingActionButton>(R.id.fab).setOnClickListener {
            Toast.makeText(this, "Добавление цепочки", Toast.LENGTH_SHORT).show()
        }
    }
    
    fun onSnooze(chainId: Int, alarmIndex: Int) {
        alarmChains.find { it.id == chainId }?.let { chain ->
            val newTime = System.currentTimeMillis() + 30 * 60 * 1000
            chain.currentTimes = chain.currentTimes.toMutableList().apply {
                this[alarmIndex] = newTime
                for (i in alarmIndex + 1 until size) this[i] = this[i - 1] + chain.interval
            }
            scheduleAlarms(chain)
        }
    }
    
    private fun scheduleAlarms(chain: AlarmChain) {
        chain.currentTimes.forEachIndexed { index, time ->
            Intent(this, AlarmReceiver::class.java).apply {
                putExtra("chainId", chain.id)
                putExtra("alarmIndex", index)
            }.also { intent ->
                alarmManager.setExact(
                    AlarmManager.RTC_WAKEUP,
                    time,
                    PendingIntent.getBroadcast(
                        this,
                        chain.id * 100 + index,
                        intent,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                    )
                )
            }
        }
    }
}
EOL

# Настраиваем GitHub Actions
mkdir -p .github/workflows
cat > .github/workflows/android.yml << 'EOL'
name: Android CI

on: [push]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up JDK 17
        uses: actions/setup-java@v3
        with:
          java-version: '17'
          distribution: 'temurin'
          
      - name: Build with Gradle
        run: ./gradlew assembleDebug
        
      - name: Upload APK
        uses: actions/upload-artifact@v4
        with:
          name: chain-alarm
          path: app/build/outputs/apk/debug/*.apk
EOL

echo "Проект успешно настроен! Откройте его в Android Studio и:"
echo "1. Синхронизируйте Gradle (File -> Sync Project with Gradle Files)"
echo "2. Запустите сборку (Build -> Make Project)"
echo "3. Запушите изменения в GitHub:"
echo "   git add ."
echo "   git commit -m 'Initial commit'"
echo "   git push"
