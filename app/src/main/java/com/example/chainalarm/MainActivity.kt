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
