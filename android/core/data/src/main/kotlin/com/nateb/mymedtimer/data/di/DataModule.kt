package com.nateb.mymedtimer.data.di

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.preferencesDataStore
import androidx.room.Room
import com.nateb.mymedtimer.data.local.AppDatabase
import com.nateb.mymedtimer.data.local.DoseLogDao
import com.nateb.mymedtimer.data.local.MedicationDao
import com.nateb.mymedtimer.data.local.ScheduleTimeDao
import com.nateb.mymedtimer.data.repository.MedicationRepositoryImpl
import com.nateb.mymedtimer.domain.repository.MedicationRepository
import dagger.Binds
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

private val Context.dataStore: DataStore<Preferences> by preferencesDataStore(name = "settings")

@Module
@InstallIn(SingletonComponent::class)
object DataModule {

    @Provides
    @Singleton
    fun provideAppDatabase(@ApplicationContext context: Context): AppDatabase =
        Room.databaseBuilder(
            context,
            AppDatabase::class.java,
            "mymedtimer.db"
        ).build()

    @Provides
    fun provideMedicationDao(db: AppDatabase): MedicationDao = db.medicationDao()

    @Provides
    fun provideScheduleTimeDao(db: AppDatabase): ScheduleTimeDao = db.scheduleTimeDao()

    @Provides
    fun provideDoseLogDao(db: AppDatabase): DoseLogDao = db.doseLogDao()

    @Provides
    @Singleton
    fun provideDataStore(@ApplicationContext context: Context): DataStore<Preferences> =
        context.dataStore
}

@Module
@InstallIn(SingletonComponent::class)
abstract class DataBindingsModule {

    @Binds
    abstract fun bindMedicationRepository(
        impl: MedicationRepositoryImpl
    ): MedicationRepository
}
