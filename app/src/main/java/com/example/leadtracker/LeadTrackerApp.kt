package com.example.leadtracker

import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.LocationOn
import androidx.compose.material.icons.filled.Map
import androidx.compose.material.icons.filled.Notes
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun LeadTrackerApp() {
    val navController = rememberNavController()
    val states = remember { StateData.getAllStates() }
    var notes by remember { mutableStateOf("") }

    val currentRoute = navController.currentBackStackEntryAsState().value?.destination?.route

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Lead Tracker") },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.primary,
                    titleContentColor = MaterialTheme.colorScheme.onPrimary
                )
            )
        },
        bottomBar = {
            NavigationBar {
                NavigationBarItem(
                    icon = { Icon(Icons.Default.Home, contentDescription = null) },
                    label = { Text("Overview") },
                    selected = currentRoute == "overview",
                    onClick = {
                        navController.navigate("overview") {
                            popUpTo("overview") { inclusive = true }
                        }
                    }
                )
                NavigationBarItem(
                    icon = { Icon(Icons.Default.LocationOn, contentDescription = null) },
                    label = { Text("States") },
                    selected = currentRoute == "states",
                    onClick = {
                        navController.navigate("states") {
                            popUpTo("overview")
                        }
                    }
                )
                NavigationBarItem(
                    icon = { Icon(Icons.Default.Map, contentDescription = null) },
                    label = { Text("Map") },
                    selected = currentRoute == "map",
                    onClick = {
                        navController.navigate("map") {
                            popUpTo("overview")
                        }
                    }
                )
                NavigationBarItem(
                    icon = { Icon(Icons.Default.Notes, contentDescription = null) },
                    label = { Text("Notes") },
                    selected = currentRoute == "notes",
                    onClick = {
                        navController.navigate("notes") {
                            popUpTo("overview")
                        }
                    }
                )
            }
        }
    ) { paddingValues ->
        NavHost(
            navController = navController,
            startDestination = "overview",
            modifier = Modifier.padding(paddingValues)
        ) {
            composable("overview") {
                OverviewScreen(states, navController)
            }
            composable("states") {
                StatesListScreen(states, navController)
            }
            composable("map") {
                MapScreen(states)
            }
            composable("state/{stateIndex}") { backStackEntry ->
                val stateIndex = backStackEntry.arguments?.getString("stateIndex")?.toIntOrNull()
                if (stateIndex != null && stateIndex < states.size) {
                    StateDetailScreen(states[stateIndex], navController)
                }
            }
            composable("notes") {
                NotesScreen(notes) { newNotes -> notes = newNotes }
            }
        }
    }
}