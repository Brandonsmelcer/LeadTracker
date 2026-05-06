package com.example.leadtracker

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.google.android.gms.maps.model.CameraPosition
import com.google.android.gms.maps.model.LatLng
import com.google.maps.android.compose.*
import com.google.android.gms.maps.model.MapStyleOptions
@Composable
fun MapScreen(states: List<State>) {
    val cameraPositionState = rememberCameraPositionState {
        position = CameraPosition.fromLatLngZoom(LatLng(36.5, -86.0), 6f)
    }

    Box(modifier = Modifier.fillMaxSize()) {
        GoogleMap(
            modifier = Modifier.fillMaxSize(),
            cameraPositionState = cameraPositionState,
            properties = MapProperties(
                isMyLocationEnabled = false,
                mapType = MapType.TERRAIN,
                mapStyleOptions = MapStyleOptions("""
                    [
                      {
                        "featureType": "road",
                        "stylers": [{ "visibility": "off" }]
                      },
                      {
                        "featureType": "transit",
                        "stylers": [{ "visibility": "off" }]
                      },
                      {
                        "featureType": "poi",
                        "stylers": [{ "visibility": "off" }]
                      }
                    ]
                """.trimIndent())
            ),
            uiSettings = MapUiSettings(
                zoomControlsEnabled = true,
                myLocationButtonEnabled = false
            )
        ) {
            states.forEach { state ->
                state.counties.forEach { county ->
                    val leadCount by county.currentLeadCount
                    val isCovered by county.currentIsCovered
                    val assignedTo by county.currentAssignedTo

                    if (leadCount > 0 || isCovered || assignedTo.isNotEmpty()) {
                        val position = LatLng(county.latitude, county.longitude)

                        MarkerInfoWindow(
                            state = MarkerState(position = position),
                            title = county.name,
                            snippet = if (assignedTo.isNotEmpty()) {
                                "Leads: $leadCount | Assigned: $assignedTo"
                            } else {
                                "Leads: $leadCount"
                            }
                        ) { marker ->
                            Column(
                                modifier = Modifier
                                    .background(
                                        if (isCovered) Color(0xFF4CAF50) else Color(0xFF2196F3),
                                        shape = MaterialTheme.shapes.small
                                    )
                                    .padding(12.dp),
                                horizontalAlignment = Alignment.Start
                            ) {
                                Text(
                                    text = county.name,
                                    color = Color.White,
                                    fontWeight = FontWeight.Bold,
                                    fontSize = 14.sp
                                )
                                Text(
                                    text = "Leads: $leadCount",
                                    color = Color.White,
                                    fontSize = 12.sp
                                )
                                if (assignedTo.isNotEmpty()) {
                                    Text(
                                        text = "Assigned: $assignedTo",
                                        color = Color.White,
                                        fontSize = 12.sp
                                    )
                                }
                                if (isCovered) {
                                    Text(
                                        text = "✓ Covered",
                                        color = Color.White,
                                        fontSize = 12.sp,
                                        fontWeight = FontWeight.Bold
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }

        // Legend
        Card(
            modifier = Modifier
                .align(Alignment.TopStart)
                .padding(16.dp),
            colors = CardDefaults.cardColors(
                containerColor = Color.White.copy(alpha = 0.9f)
            )
        ) {
            Column(
                modifier = Modifier.padding(12.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Text(
                    text = "Legend",
                    fontWeight = FontWeight.Bold,
                    fontSize = 14.sp
                )
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Box(
                        modifier = Modifier
                            .size(16.dp)
                            .background(Color(0xFF2196F3), CircleShape)
                    )
                    Text("Active", fontSize = 12.sp)
                }
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Box(
                        modifier = Modifier
                            .size(16.dp)
                            .background(Color(0xFF4CAF50), CircleShape)
                    )
                    Text("Covered", fontSize = 12.sp)
                }
            }
        }
    }
}