package com.example.airbridge

import android.content.Intent
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService

class AirBridgeTileService : TileService() {
    override fun onClick() {
        super.onClick()
        qsTile?.state = Tile.STATE_ACTIVE
        qsTile?.updateTile()
        val launch = packageManager.getLaunchIntentForPackage(packageName) ?: return
        launch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        launch.putExtra("open_receiver", true)
        startActivityAndCollapse(launch)
    }
}
