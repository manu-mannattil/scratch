#!/bin/sh
#
# sm-j327a_debloat.sh -- debloat Samsung SM-J327A
#
# Usage: sm-j327a_debloat.sh
#
# This script will uninstall a bunch of bloatware (e.g., Facebook, AT&T
# apps) from the Samsung SM-J327A (AT&T Galaxy Prime 2 SM-J327A) phone
# that cannot otherwise be uninstalled [1].  For this script to work,
# you will need to enable developer tools and USB debugging on your
# phone.
#
# [1]: https://www.xda-developers.com/uninstall-carrier-oem-bloatware-without-root-access/
#
# Requires: adb
#

backup_dir="$PWD/appbackup"
mkdir -p "$backup_dir"

info() {
    echo >&2 "---> $*"
}

adb_uninstall() {
    info "backing up ${1}"

    apk=$(adb shell pm path "$1" 2>/dev/null | cut -d: -f2-)
    [ -z "$apk" ] && {
        info "package ${1} not installed on device"
        return 1
    }

    # Backup the APK before uninstalling.
    rm -rf "${backup_dir}/${1}.apk"
    adb pull "$apk" "${backup_dir}/${1}.apk"

    if [ -f "${backup_dir}/${1}.apk" ]
    then
        adb shell pm uninstall -k --user 0 "$1"
    else
        info "error backing up ${1}"
        return 1
    fi
    info "removed ${1}"
}

adb_uninstall com.aetherpal.attdh.se
adb_uninstall com.android.bio.face.service
adb_uninstall com.android.bookmarkprovider
adb_uninstall com.android.dreams.phototable
adb_uninstall com.android.egg
adb_uninstall com.android.printspooler
adb_uninstall com.android.providers.blockednumber
adb_uninstall com.asurion.android.mobilerecovery.att
adb_uninstall com.att.android.attsmartwifi
adb_uninstall com.att.callprotect
adb_uninstall com.att.iqi
adb_uninstall com.att.mobiletransfer
adb_uninstall com.att.myWireless
adb_uninstall com.cequint.ecid
adb_uninstall com.cnn.mobile.android.phone
adb_uninstall com.contextlogic.wish
adb_uninstall com.diotek.sec.lookup.dictionary
adb_uninstall com.directv.dvrscheduler
adb_uninstall com.dna.solitaireapp
adb_uninstall com.drivemode
adb_uninstall com.dsi.ant.antplus
adb_uninstall com.dsi.ant.sample.acquirechannels
adb_uninstall com.dsi.ant.server
adb_uninstall com.dsi.ant.service.socket
adb_uninstall com.dti.att
adb_uninstall com.enhance.gameservice
adb_uninstall com.facebook.appmanager
adb_uninstall com.facebook.katana
adb_uninstall com.facebook.services
adb_uninstall com.facebook.system
adb_uninstall com.google.android.apps.docs
adb_uninstall com.google.android.apps.photos
adb_uninstall com.google.android.apps.tachyon
adb_uninstall com.google.android.gm
adb_uninstall com.google.android.googlequicksearchbox
adb_uninstall com.google.android.music
adb_uninstall com.google.android.printservice.recommendation
adb_uninstall com.google.android.videos
adb_uninstall com.gsn.android.tripeaks
adb_uninstall com.hbo.hbonow
adb_uninstall com.knox.vpn.proxyhandler
adb_uninstall com.locationlabs.cni.att
adb_uninstall com.locationlabs.sparkle.blue
adb_uninstall com.lookout
adb_uninstall com.matchboxmobile.wisp
adb_uninstall com.microsoft.office.excel
adb_uninstall com.microsoft.office.powerpoint
adb_uninstall com.microsoft.office.word
adb_uninstall com.microsoft.skydrive
adb_uninstall com.mobeam.barcodeService
adb_uninstall com.osp.app.signin
adb_uninstall com.samsung.aasaservice
adb_uninstall com.samsung.android.allshare.service.fileshare
adb_uninstall com.samsung.android.allshare.service.mediashare
adb_uninstall com.samsung.android.allshare.servuce.mediashare
adb_uninstall com.samsung.android.app.amcagent
adb_uninstall com.samsung.android.app.aodservice
adb_uninstall com.samsung.android.app.appsedge
adb_uninstall com.samsung.android.app.galaxyfinder
adb_uninstall com.samsung.android.app.mirrorlink
adb_uninstall com.samsung.android.app.notes
adb_uninstall com.samsung.android.app.omcagent
adb_uninstall com.samsung.android.app.simplesharing
adb_uninstall com.samsung.android.app.spage
adb_uninstall com.samsung.android.app.talkback
adb_uninstall com.samsung.android.app.vrsetupwizards
adb_uninstall com.samsung.android.app.vrsetupwizardstub
adb_uninstall com.samsung.android.app.watchmanager
adb_uninstall com.samsung.android.app.watchmanagerstub
adb_uninstall com.samsung.android.app.withtc
adb_uninstall com.samsung.android.app.withtv
adb_uninstall com.samsung.android.authfw
adb_uninstall com.samsung.android.bbc.bbcagent
adb_uninstall com.samsung.android.beaconmanager
adb_uninstall com.samsung.android.bio.face.service
adb_uninstall com.samsung.android.bixby.agent
adb_uninstall com.samsung.android.bixby.agent.dummy
adb_uninstall com.samsung.android.bixby.es.globalaction
adb_uninstall com.samsung.android.bixby.plmsync
adb_uninstall com.samsung.android.bixby.voiceinput
adb_uninstall com.samsung.android.bixby.wakeup
adb_uninstall com.samsung.android.clipboarduiservice
adb_uninstall com.samsung.android.da.daagent
adb_uninstall com.samsung.android.dlp.service
adb_uninstall com.samsung.android.dqagent
adb_uninstall com.samsung.android.easysetup
adb_uninstall com.samsung.android.email.provider
adb_uninstall com.samsung.android.fmm
adb_uninstall com.samsung.android.game.gamehome
adb_uninstall com.samsung.android.game.gametools
adb_uninstall com.samsung.android.hmt.vrshell
adb_uninstall com.samsung.android.hmt.vrsvc
adb_uninstall com.samsung.android.intelligenceservice2
adb_uninstall com.samsung.android.keyguardwallpaperupdator
adb_uninstall com.samsung.android.knox.analytics.uploader
adb_uninstall com.samsung.android.knox.containeragent
adb_uninstall com.samsung.android.knox.containercore
adb_uninstall com.samsung.android.lool
adb_uninstall com.samsung.android.mateagent
adb_uninstall com.samsung.android.mdm
adb_uninstall com.samsung.android.mobileservice
adb_uninstall com.samsung.android.oneconnect
adb_uninstall com.samsung.android.providers.context
adb_uninstall com.samsung.android.rubin.app
adb_uninstall com.samsung.android.samsungpass
adb_uninstall com.samsung.android.samsungpassautofill
adb_uninstall com.samsung.android.samsungpositioning
adb_uninstall com.samsung.android.scloud
adb_uninstall com.samsung.android.sdk.professionalaudio.app.audioconnectionservice
adb_uninstall com.samsung.android.sdk.professionalaudio.utility.jammonitor
adb_uninstall com.samsung.android.securitylogagent
adb_uninstall com.samsung.android.slinkcloud
adb_uninstall com.samsung.android.smartcallprovider
adb_uninstall com.samsung.android.smartface
adb_uninstall com.samsung.android.smartmirroring
adb_uninstall com.samsung.android.sm.devicesecurity
adb_uninstall com.samsung.android.sm.policy
adb_uninstall com.samsung.android.spayfw
adb_uninstall com.samsung.android.spdfnote
adb_uninstall com.samsung.android.svcagent
adb_uninstall com.samsung.android.svoice
adb_uninstall com.samsung.android.themestore
adb_uninstall com.samsung.android.unifiedprofile
adb_uninstall com.samsung.android.video
adb_uninstall com.samsung.android.visioncloudagent
adb_uninstall com.samsung.android.visionintelligence
adb_uninstall com.samsung.android.widgetapp.yagooedge.sport
adb_uninstall com.samsung.android.widgetapp.yahooedge.finance
adb_uninstall com.samsung.android.widgetapp.yahooedge.sport
adb_uninstall com.samsung.app.newtrim
adb_uninstall com.samsung.clipboardsaveservice
adb_uninstall com.samsung.crane
adb_uninstall com.samsung.dcmservice
adb_uninstall com.samsung.enhanceservice
adb_uninstall com.samsung.faceservice
adb_uninstall com.samsung.fresco.logging
adb_uninstall com.samsung.klmsagent
adb_uninstall com.samsung.know.securefolder.setuppage
adb_uninstall com.samsung.knox.securefolder
adb_uninstall com.samsung.knox.securefolder.setuppage
adb_uninstall com.samsung.oh
adb_uninstall com.samsung.sec.android.application.csc
adb_uninstall com.samsung.SMT
adb_uninstall com.samsung.storyservice
adb_uninstall com.samsung.svoice.sync
adb_uninstall com.samsung.systemui.bixby
adb_uninstall com.samsung.vvm
adb_uninstall com.sec.android.app.apex
adb_uninstall com.sec.android.app.billing
adb_uninstall com.sec.android.app.desktoplauncher
adb_uninstall com.sec.android.app.easysetup
adb_uninstall com.sec.android.app.samsungapps
adb_uninstall com.sec.android.app.sbrowser
adb_uninstall com.sec.android.app.scloud
adb_uninstall com.sec.android.app.sns3
adb_uninstall com.sec.android.desktopmode.uiservice
adb_uninstall com.sec.android.easyMover.Agent
adb_uninstall com.sec.android.game.gamehome
adb_uninstall com.sec.android.mimae.gear360editor
adb_uninstall com.sec.android.mimage.gear360editor
adb_uninstall com.sec.android.service.health
adb_uninstall com.sec.android.servicehealth
adb_uninstall com.sec.android.widgetapp.samsungapps
adb_uninstall com.sec.android.widgetapp.webmanual
adb_uninstall com.sec.enterprise.knox.attestation
adb_uninstall com.sec.enterprise.knox.cloudmdm.smdms
adb_uninstall com.sec.epdgtestapp
adb_uninstall com.sec.location.nsflp2
adb_uninstall com.sec.spp.push
adb_uninstall com.sem.factoryapp
adb_uninstall com.servicemagic.consumer
adb_uninstall com.skms.android.agent
adb_uninstall com.skype.raider
adb_uninstall com.synchronoss.dcs.att.r2g
adb_uninstall com.telenav.app.android.cingular
adb_uninstall com.trustonic.tuiservice
adb_uninstall com.wavemarket.waplauncher
adb_uninstall com.yelp.android
adb_uninstall de.axelspringer.yana.zeropage
adb_uninstall in.playsimple.wordtrip
adb_uninstall net.aetherpal.device
adb_uninstall tv.pluto.android
