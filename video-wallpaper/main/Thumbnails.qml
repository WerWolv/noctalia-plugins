pragma ComponentBehavior: Bound
import Qt.labs.folderlistmodel
import QtQuick
import Quickshell
import Quickshell.Io

import qs.Commons
import qs.Services.UI

Item {
    id: root
    required property var pluginApi


    /***************************
    * PROPERTIES
    ***************************/
    required property string currentWallpaper 
    required property bool thumbCacheReady
    required property FolderListModel folderModel

    readonly property string thumbCacheFolderPath: ImageCacheService.wpThumbDir + "video-wallpaper"
    property int _thumbGenIndex: 0

    property list<string> thumbCacheFolder: []
    property bool thumbCacheFolderReady: false

    /***************************
    * FUNCTIONS
    ***************************/
    function clearThumbCacheReady() {
        if(pluginApi != null && thumbCacheReady) {
            pluginApi.pluginSettings.thumbCacheReady = false;
            pluginApi.saveSettings();
        }
    }

    function setThumbCacheReady() {
        if(pluginApi != null && !thumbCacheReady) {
            pluginApi.pluginSettings.thumbCacheReady = true;
            pluginApi.saveSettings();
        }
    }


    function getThumbPath(videoPath: string): string {
        const file = videoPath.split('/').pop();

        return `${thumbCacheFolderPath}/${file}.bmp`
    }

    function reloadThumbFolder() {
        thumbCacheFolder = [];
        thumbCacheFolderReady = false;
        thumbCacheFolderProc.running = true;
    }


    function startColorGen() {
        // If the thumbCacheFolderFiles aren't ready try in a bit
        if(!root.thumbCacheFolderReady){
            if(thumbCacheFolderProc.running) {
                // Run the timer
                startColorGenTimer.restart();
            } else {
                // Try to run the process again since the ready flag is off
                thumbCacheFolderProc.running = true;
            }
        }

        const thumbPath = root.getThumbPath(root.currentWallpaper);
        if (root.thumbCacheFolder.includes(thumbPath)) {
            Logger.d("video-wallpaper", "Generating color scheme based on video wallpaper!");
            WallpaperService.changeWallpaper(thumbPath);
        } else {
            // Try to create the thumbnail again
            // just a fail safe if the current wallpaper isn't included in the wallpapers folder
            const videoPath = folderModel.get(root._thumbGenIndex, "filePath");
            const thumbUrl = root.getThumbPath(videoPath);

            Logger.d("video-wallpaper", "Thumbnail not found:", thumbPath);
            thumbColorGenProc.command = ["sh", "-c", `ffmpeg -y -i ${videoPath} -vframes:v 1 ${thumbUrl}`]
            thumbColorGenProc.running = true;

            // Since we have updated the thumbnails set the thumbnails folder flag off
            reloadThumbFolder();
        }
    }


    function thumbGeneration() {
        if(pluginApi == null) return;

        // Reset the state of thumbCacheReady
        clearThumbCacheReady();

        while(root._thumbGenIndex < folderModel.count) {
            const videoPath = folderModel.get(root._thumbGenIndex, "filePath");
            const thumbPath = root.getThumbPath(videoPath);
            root._thumbGenIndex++;
            // Check if file already exists, otherwise create it with ffmpeg
            if (root.thumbCacheFolder.includes(thumbPath)) {
                Logger.d("video-wallpaper", `Creating thumbnail for video: ${videoPath}`);

                // With scale
                //thumbProc.command = ["sh", "-c", `ffmpeg -y -i ${videoUrl} -vf "scale=1080:-1" -vframes:v 1 ${thumbUrl}`]
                thumbProc.command = ["sh", "-c", `ffmpeg -y -i ${videoPath} -vframes:v 1 ${thumbPath}`]
                thumbProc.running = true;
                return;
            }
        }

        // The thumbnail generation has looped over every video and finished the generation
        // Update the thumbnail folder
        reloadThumbFolder();

        root._thumbGenIndex = 0;
        setThumbCacheReady();
    }

    function thumbRegenerate() {
        if(pluginApi == null) return;

        clearThumbCacheReady();

        thumbProc.command = ["sh", "-c", `rm -rf ${thumbCacheFolderPath} && mkdir -p ${thumbCacheFolderPath}`]
        thumbProc.running = true;
    }


    /***************************
    * COMPONENTS
    ***************************/
    Process {
        // Process to create the thumbnail folder
        id: thumbInit
        command: ["sh", "-c", `mkdir -p ${root.thumbCacheFolderPath}`]
        running: true
    }

    Process {
        id: thumbProc
        onRunningChanged: {
            if (thumbProc.running)
                return;

            // Try to create the thumbnails if they don't exist.
            root.thumbGeneration();
        }
    }

    Process {
        id: thumbCacheFolderProc
        command: ["sh", "-c", `find ${root.thumbCacheFolderPath} -name "*.bmp"`]
        running: true
        stdout: SplitParser {
            onRead: line => {
                root.thumbCacheFolder.push(line);
            }
        }
        onExited: root.thumbCacheFolderReady = true;
    }

    Process {
        id: thumbColorGenProc
        onExited: root.startColorGen();
    }

    Timer {
        id: startColorGenTimer
        interval: 50
        repeat: false
        running: false
        triggeredOnStart: false
        onTriggered: root.startColorGen();
    }
}
