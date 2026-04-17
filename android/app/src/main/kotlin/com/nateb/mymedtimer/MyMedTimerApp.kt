package com.nateb.mymedtimer

import android.app.Application
import com.nateb.mymedtimer.data.notification.NotificationChannelManager
import dagger.hilt.android.HiltAndroidApp
import javax.inject.Inject

@HiltAndroidApp
class MyMedTimerApp : Application() {

    @Inject
    lateinit var notificationChannelManager: NotificationChannelManager

    override fun onCreate() {
        super.onCreate()
        notificationChannelManager.createChannels()
    }
}
