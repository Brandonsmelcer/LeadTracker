package com.example.leadtracker

import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf

data class County(
    val name: String,
    val leadCount: Int = 0,
    val isCovered: Boolean = false,
    val assignedTo: String = "",
    val latitude: Double = 0.0,
    val longitude: Double = 0.0
) {
    var currentLeadCount = mutableIntStateOf(leadCount)
    var currentIsCovered = mutableStateOf(isCovered)
    var currentAssignedTo = mutableStateOf(assignedTo)
}

data class State(
    val name: String,
    val abbreviation: String,
    val counties: List<County>,
    val centerLat: Double,
    val centerLng: Double
) {
    fun totalLeads(): Int = counties.sumOf { it.currentLeadCount.intValue }
    fun coveredCount(): Int = counties.count { it.currentIsCovered.value }
}

object StateData {

    fun getTennesseeCounties(): List<County> {
        return listOf(
            County("Davidson", latitude = 36.1627, longitude = -86.7816),
            County("Shelby", latitude = 35.1495, longitude = -89.9771),
            County("Knox", latitude = 35.9606, longitude = -83.9207),
            County("Hamilton", latitude = 35.0456, longitude = -85.2672),
            County("Rutherford", latitude = 35.8456, longitude = -86.3903),
            County("Williamson", latitude = 35.9251, longitude = -86.8689),
            County("Sumner", latitude = 36.4620, longitude = -86.4400),
            County("Montgomery", latitude = 36.5298, longitude = -87.3595),
            County("Anderson", latitude = 36.0981, longitude = -84.1755),
            County("Bedford", latitude = 35.5090, longitude = -86.4400)
        )
    }

    fun getKentuckyCounties(): List<County> {
        return listOf(
            County("Jefferson", latitude = 38.2527, longitude = -85.7585),
            County("Fayette", latitude = 38.0406, longitude = -84.5037),
            County("Kenton", latitude = 38.9598, longitude = -84.5467),
            County("Boone", latitude = 38.9981, longitude = -84.7299),
            County("Warren", latitude = 36.9686, longitude = -86.4808),
            County("Hardin", latitude = 37.6989, longitude = -85.9641),
            County("Daviess", latitude = 37.7279, longitude = -87.1142),
            County("Campbell", latitude = 39.0076, longitude = -84.3733),
            County("Madison", latitude = 37.7476, longitude = -84.2964),
            County("McCracken", latitude = 37.0501, longitude = -88.6848)
        )
    }

    fun getArkansasCounties(): List<County> {
        return listOf(
            County("Pulaski", latitude = 34.7465, longitude = -92.2896),
            County("Benton", latitude = 36.3729, longitude = -94.2088),
            County("Washington", latitude = 36.0625, longitude = -94.1574),
            County("Sebastian", latitude = 35.2317, longitude = -94.3985),
            County("Faulkner", latitude = 35.1284, longitude = -92.3996),
            County("Craighead", latitude = 35.8365, longitude = -90.7043),
            County("Saline", latitude = 34.6401, longitude = -92.6299),
            County("Garland", latitude = 34.5037, longitude = -93.0546),
            County("White", latitude = 35.2537, longitude = -91.7293),
            County("Jefferson", latitude = 34.2011, longitude = -91.9318)
        )
    }

    fun getOklahomaCounties(): List<County> {
        return listOf(
            County("Oklahoma", latitude = 35.5376, longitude = -97.4150),
            County("Tulsa", latitude = 36.1540, longitude = -95.9928),
            County("Cleveland", latitude = 35.2284, longitude = -97.3370),
            County("Canadian", latitude = 35.5376, longitude = -97.8803),
            County("Comanche", latitude = 34.6595, longitude = -98.4842),
            County("Rogers", latitude = 36.3376, longitude = -95.6025),
            County("Creek", latitude = 35.9151, longitude = -96.3700),
            County("Wagoner", latitude = 35.9595, longitude = -95.3696),
            County("Payne", latitude = 36.0765, longitude = -96.9975),
            County("Muskogee", latitude = 35.6887, longitude = -95.3696)
        )
    }

    fun getWestVirginiaCounties(): List<County> {
        return listOf(
            County("Kanawha", latitude = 38.3498, longitude = -81.6326),
            County("Berkeley", latitude = 39.4568, longitude = -77.9647),
            County("Cabell", latitude = 38.4192, longitude = -82.2454),
            County("Wood", latitude = 39.2673, longitude = -81.5615),
            County("Monongalia", latitude = 39.6295, longitude = -80.0440),
            County("Raleigh", latitude = 37.7782, longitude = -81.1870),
            County("Harrison", latitude = 39.2798, longitude = -80.3684),
            County("Jefferson", latitude = 39.3168, longitude = -77.8647),
            County("Mercer", latitude = 37.4093, longitude = -81.1012),
            County("Ohio", latitude = 40.0645, longitude = -80.6990)
        )
    }

    fun getAllStates(): List<State> {
        return listOf(
            State("Tennessee", "TN", getTennesseeCounties(), 35.5175, -86.5804),
            State("Kentucky", "KY", getKentuckyCounties(), 37.8393, -84.2700),
            State("Arkansas", "AR", getArkansasCounties(), 34.7465, -92.2896),
            State("Oklahoma", "OK", getOklahomaCounties(), 35.4676, -97.5164),
            State("West Virginia", "WV", getWestVirginiaCounties(), 38.5976, -80.4549)
        )
    }
}