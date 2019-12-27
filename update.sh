#!/bin/bash
set -e

#Repositories, their tmp dirs and GPG keys
fdroid="https://f-droid.org/repo"
fdroid_dir="tmp/fdroid"
fdroid_key="37D2C98789D8311948394E3E41E7044E1DBA2E89" #F-Droid's repo GPG signing key "F-Droid <admin@f-droid.org>"

microg="https://microg.org/fdroid/repo"
microg_dir="tmp/microg"
microg_key="???" #WIP

bromite="https://fdroid.bromite.org/fdroid/repo"
bromite_dir="tmp/bromite"
bromite_key="???" #WIP

#Clean-up and prepare dirs
rm -Rf bin tmp apps.mk Android.mk
mkdir -p bin tmp

addCopy() {
cat >> Android.mk <<EOF
include \$(CLEAR_VARS)
LOCAL_MODULE := $2
LOCAL_MODULE_TAGS := optional
LOCAL_SRC_FILES := bin/$1
LOCAL_MODULE_CLASS := APPS
LOCAL_CERTIFICATE := PRESIGNED
LOCAL_OVERRIDES_PACKAGES := "$3"
include \$(BUILD_PREBUILT)

EOF
echo -e "\t$2 \\" >> apps.mk
}

cat > Android.mk <<EOF
LOCAL_PATH := \$(my-dir)

EOF
echo -e 'PRODUCT_PACKAGES += \\' > apps.mk

##### FUNCTIONS
getGPGKeys() {
#TODO: check if key is already existing to speed up stuff query
#Also keyserver doesnt repond often
		key="$1"
		
		gpg --keyserver pgp.mit.edu --recv-key "$key"
}
verifyApks() {
		apk_signature="$1"
		
		gpg --keyid-format 0xlong --verify "$apk_signature"
}
downloadStuff() {
	    what="$1"
		where="$2"
		
		while ! wget --connect-timeout=10 --tries=2 --compression=gzip "$what" -O "$where";do sleep 1;done
}
downloadFromRepo() {
#downloadFromAnyFdroidCompatibleRepo repo repo_dir packageName overrides	
		repo="$1"
		repo_dir="$2"
		package="$3"
		overrides="$4"
				
		mkdir -p "$repo_dir"
	if [ ! -f "$repo_dir"/index.xml ];then
	
		#TODO: Check security keys
		downloadStuff "$repo"/index.jar "$repo_dir"/index.jar
		unzip -p "$repo_dir"/index.jar index.xml > "$repo_dir"/index.xml
	fi
	
		marketvercode="$(xmlstarlet sel -t -m '//application[id="'"$package"'"]' -v ./marketvercode "$repo_dir"/index.xml || true)"
		apk="$(xmlstarlet sel -t -m '//application[id="'"$package"'"]/package[versioncode="'"$marketvercode"'"]' -v ./apkname "$repo_dir"/index.xml || xmlstarlet sel -t -m '//application[id="'"$package"'"]/package[1]' -v ./apkname "$repo_dir"/index.xml)"
		downloadStuff "$repo"/"$apk" bin/"$apk"
	
		#TODO: Check security keys -> WIP. GPG check works only for original fdroid repo!
		# Get signatures and verify them
		#if [ "$repo" == "$fdroid" ];then
		#getGPGKeys "$fdroid_key"
		#downloadStuff "$repo" bin/"$apk".asc
		#Should add to this function: exit code check and error message if non 0
		#verifyApks bin/"$apk".asc
		#fi

		addCopy "$apk" "$package" "$overrides"
}
#####

##### APK'S OF CHOICE :D
#downloadFromRepo repo repo_dir package_name overrides

#phh's Superuser
#downloadFromRepo "$fdroid" "$fdroid_dir" "me.phh.superuser" "Superuser"
#YouTube viewer
#downloadFromFdroid org.schabi.newpipe
#Ciphered SMS
#downloadFromFdroid org.smssecure.smssecure "messaging"
#Navigation
#downloadFromFdroid net.osmand.plus
#Web browser
#downloadFromFdroid org.mozilla.fennec_fdroid "Browser2 QuickSearchBox"
#downloadFromFdroid acr.browser.lightning "Browser2 QuickSearchBox"
#Calendar
#downloadFromFdroid ws.xsoh.etar Calendar
#Public transportation
#downloadFromFdroid de.grobox.liberario
#Pdf viewer
#downloadFromFdroid com.artifex.mupdf.viewer.app
#Keyboard/IME
#downloadFromFdroid com.menny.android.anysoftkeyboard "LatinIME OpenWnn"
#Play Store download
#downloadFromFdroid com.github.yeriomin.yalpstore
#downloadFromFdroid com.aurora.store
#Mail client
#downloadFromFdroid com.fsck.k9 "Email"
#Ciphered Instant Messaging
#downloadFromFdroid im.vector.alpha
#Calendar/Contacts sync
#downloadFromFdroid at.bitfire.davdroid
#Nextcloud client
#downloadFromFdroid com.nextcloud.client
#Lawnchair launcher
#downloadFromFdroid ch.deletescape.lawnchair.plah "Launcher3QuickStep Launcher2 Launcher3"

#TODO: Some social network?
#Facebook? Twitter? Reddit? Mastodon?

#downloadFromFdroid org.fdroid.fdroid

#MicroG support + location
#downloadFromMicroG com.google.android.gms
#downloadFromMicroG com.google.android.gsf
#downloadFromMicroG com.android.vending
#downloadFromMicroG org.microg.gms.droidguard
#downloadFromFdroid org.microg.nlp.backend.nominatim

downloadFromRepo "$fdroid" "$fdroid_dir" com.fsck.k9 "Email"
downloadFromRepo "$microg" "$microg_dir" com.android.vending "Google Play Store"
downloadFromRepo "$bromite" "$bromite_dir" com.android.webview "Android System WebView"

echo >> apps.mk

#Remove temporary folder and signatures to leave clean
rm -Rf tmp/ bin/*.asc
