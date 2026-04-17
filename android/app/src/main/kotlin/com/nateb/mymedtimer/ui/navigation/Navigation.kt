package com.nateb.mymedtimer.ui.navigation

import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.DateRange
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.navigation.NavDestination.Companion.hierarchy
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import com.nateb.mymedtimer.feature.addedit.AddEditScreen
import com.nateb.mymedtimer.feature.history.HistoryScreen
import com.nateb.mymedtimer.feature.medlist.MedListScreen
import com.nateb.mymedtimer.feature.settings.SettingsScreen

private data class BottomNavItem(
    val label: String,
    val icon: androidx.compose.ui.graphics.vector.ImageVector,
    val route: String,
)

private val bottomNavItems = listOf(
    BottomNavItem("Meds", Icons.Default.Home, Screen.MedList.route),
    BottomNavItem("History", Icons.Default.DateRange, Screen.History.route),
    BottomNavItem("Settings", Icons.Default.Settings, Screen.Settings.route),
)

@Composable
fun AppNavigation() {
    val navController = rememberNavController()
    val navBackStackEntry by navController.currentBackStackEntryAsState()
    val currentDestination = navBackStackEntry?.destination

    val showBottomBar = currentDestination?.route in bottomNavItems.map { it.route }

    Scaffold(
        bottomBar = {
            if (showBottomBar) {
                NavigationBar {
                    bottomNavItems.forEach { item ->
                        NavigationBarItem(
                            icon = { Icon(item.icon, contentDescription = item.label) },
                            label = { Text(item.label) },
                            selected = currentDestination?.hierarchy?.any { it.route == item.route } == true,
                            onClick = {
                                navController.navigate(item.route) {
                                    popUpTo(navController.graph.findStartDestination().id) {
                                        saveState = true
                                    }
                                    launchSingleTop = true
                                    restoreState = true
                                }
                            },
                        )
                    }
                }
            }
        },
    ) { innerPadding ->
        NavHost(
            navController = navController,
            startDestination = Screen.MedList.route,
            modifier = Modifier.padding(innerPadding),
        ) {
            composable(Screen.MedList.route) {
                MedListScreen(
                    onAddMed = { navController.navigate(Screen.AddMed.route) },
                    onEditMed = { medId -> navController.navigate(Screen.EditMed.createRoute(medId)) }
                )
            }
            composable(Screen.History.route) { HistoryScreen() }
            composable(Screen.Settings.route) { SettingsScreen() }
            composable(Screen.AddMed.route) {
                AddEditScreen(onNavigateBack = { navController.popBackStack() })
            }
            composable(
                route = Screen.EditMed.route,
                arguments = listOf(navArgument("medId") { type = NavType.StringType }),
            ) {
                AddEditScreen(onNavigateBack = { navController.popBackStack() })
            }
        }
    }
}
