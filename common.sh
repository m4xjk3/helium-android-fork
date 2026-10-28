export SCRIPT_DIR=$(realpath $(dirname $0))

replace() {
    export org=$2 new=$3
    find $1 -type f -exec sed -i 's@'$org'@'$new'@g' {} \;
}

set_keys() {
    mkdir -p $SCRIPT_DIR/keys
    if [ -n "$LOCAL_TEST_JKS" ] && [ -n "$STORE_TEST_JKS" ]; then
        echo "$LOCAL_TEST_JKS" | base64 -d > $SCRIPT_DIR/keys/local.properties
        echo "$STORE_TEST_JKS" | base64 -d > $SCRIPT_DIR/keys/test.jks
        unset LOCAL_TEST_JKS
        unset STORE_TEST_JKS
        return
    fi

    # No signing secrets were supplied. Generate an ephemeral keystore so that
    # CI can produce an installable APK. Builds signed this way cannot be
    # installed over each other (different keys) and must not be published.
    echo "WARNING: no signing secrets, generating an ephemeral keystore" >&2
    local pass="helium-android"
    if ! command -v keytool >/dev/null 2>&1; then
        echo "ERROR: keytool not found, install a JDK or provide STORE_TEST_JKS/LOCAL_TEST_JKS" >&2
        exit 1
    fi
    keytool -genkeypair -keystore "$SCRIPT_DIR/keys/test.jks" -alias helium \
        -keyalg RSA -keysize 2048 -validity 10000 \
        -storepass "$pass" -keypass "$pass" \
        -dname "CN=Helium Android, O=Helium, C=US" >/dev/null 2>&1 || exit 1
    cat > "$SCRIPT_DIR/keys/local.properties" <<EOF
keyAlias=helium
keyPassword=$pass
storePassword=$pass
EOF
}

sign_apk() {
    export apksigner=$(find $ANDROID_HOME/build-tools -name apksigner | sort | tail -n 1)
    source $SCRIPT_DIR/keys/local.properties
    $apksigner sign -verbose -ks $SCRIPT_DIR/keys/test.jks --ks-pass pass:$storePassword --key-pass pass:$keyPassword --ks-key-alias $keyAlias --out $2 $1 || exit 1
}

sign_aab() {
    source $SCRIPT_DIR/keys/local.properties
    jarsigner -verbose -sigalg SHA256withRSA -digestalg SHA-256 -keystore $SCRIPT_DIR/keys/test.jks -storepass $storePassword -keypass $keyPassword -signedjar $2 $1 $keyAlias || exit 1
}

version_lt() {
  [ "$1" != "$2" ] && [ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | head -n1)" = "$1" ]
}
