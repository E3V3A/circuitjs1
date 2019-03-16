#!/usr/bin/env bash
# ecl2mvn.sh -- Convert Eclipse source paths to Maven based builds
#----------------------------------------------------------------------
# Author:       E:V:A
# Date:         2019-03-14
# URL:          https://githubub.com/E3V3A/circuitjs1/
# 
# Description:  
#   This Bash script converts source PATH's of the original circuitJS1 
#   repo, from using Eclipse + GWT plugin, to using Maven type builds 
#   as specified in the single pom.xml. It is also required if you 
#   want to build using the supplied Gradle build script.
#----------------------------------------------------------------------

#--------------------------------------
# Color helpers
#--------------------------------------
function sayok() {
    if [[ $TERM == *"xterm"* ]]; then
        echo -e '\x1b[33mok\x1b[0m'
    else
        echo "ok"
    fi
}
function fail() {
    if [[ $TERM == *"xterm"* ]]; then
        echo -e '\x1b[31mfailed\x1b[0m'
    else
        echo "fail"
    fi
}

#--------------------------------------
# Check that we're in the right place
#--------------------------------------
echo -n "Checking current location: "
DIR=$(basename "${PWD}")
if [[ ! $DIR == *"circuitjs1"* ]]; then
    fail
    echo "Make sure you are in the circuitjs1 repo. Exiting."
    exit 1
fi
sayok
#echo "ok"

#--------------------------------------
# (1) Change Eclipse source paths to Maven paths
#--------------------------------------
MSRC="src/com"
MTGT="src/main/java/"
# perhaps without quotes?

echo -n "Checking for Eclipse src directory: "
if [ -d "src" ]; then
    sayok
else
    fail
    echo "Eclipse \"src\" directory not found! Exiting."
    exit 1
fi

echo -n "Creating new target directory: ${MTGT}  "
mkdir -p "$MTGT" && sayok || fail
sleep 1
echo -n "Moving ${MSRC}/* to new location: ${MTGT}  "
mv -inf src/com src/main/java/
#mv -inf $MSRC $MSRC

retVal=$?
if [ $retVal -ne 0 ]; then
    fail
else
    sayok
fi

#--------------------------------------
# (2) Add: pom.xml
#--------------------------------------
# Here we download the E3V3A pom.xml template:
echo -n "Checking for Maven pom.xml  "
if [ -f pom.xml ]; then
    sayok
else
    fail
    echo -e "File pom.xml not found! Downloading...\n"
    wget https://raw.githubusercontent.com/E3V3A/circuitjs1/master/pom.xml
fi

# ToDo: Add check for build.gradle

#--------------------------------------
# (3) Update Version string in: pom.xml
#--------------------------------------
# The true Version is defined by "versionString" in:
# ./src/main/java/com/lushprojects/circuitjs1/client/circuitjs1.java
#  public static final String versionString="2.2.2js (isharp)";
echo
echo "Current version string in:  circuitjs1.java"
#cat src/main/java/com/lushprojects/circuitjs1/client/circuitjs1.java |grep -E "versionString"
SVER=$(cat src/main/java/com/lushprojects/circuitjs1/client/circuitjs1.java |grep -E "versionString" | sed -E 's/^(.+versionString=\")(.+)\";/\2/')
echo "$SVER"
echo "Current version string in:  pom.xml"
#cat pom.xml | grep -B1 -E '^.{1}<version>'
cat pom.xml | grep -E '^.{1}<version>'

#--------------------------------------
# ToDo:  Replace \2 with $SVER
# NOTE:  sed substition with bash variables are only possible 
#        when using double quoted (") sed expressions.
#--------------------------------------
# Extract properly formatted version string: "2.2.3" from "2.2.3js (isharp)"
SVER=$(echo $SVER | sed -E 's/([0-9\.]+).+/\1/')
echo "Updating version string to:  $SVER"
# We use in-place sed substitution:
#sed -E "s/^(.{1}<version>)([0-9\.]+)(<\/version>)/\1$SVER\3/" -i ./pom.xml && sayok || fail
sed -E "s/^(.{1}<version>)([0-9\.]+)(<\/version>)/\1$SVER\3/" ./pom.xml | grep -E '^.{1}<version>'

#--------------------------------------
# (4) Update classpathentry in: .classpath
#--------------------------------------
# from:     <classpathentry kind="src" path="src"/>
# to:       <classpathentry kind="src" path="src/main/java"/>
# wget -q https://github.com/sharpie7/circuitjs1/raw/master/.classpath
echo -en "\nChanging 'classpathentry' in: .classpath "
sed -E 's/path="src"/path="src\/main\/java"/' -i ./.classpath && sayok || fail

#--------------------------------------
# (5) Add: war/index.html
#--------------------------------------
echo -n "Creating: war/index.html  "
#cat war/index.html <<EOF # &>/dev/null
tee ./war/index.html <<EOF &>/dev/null
<!doctype HTML>
<html>
<head><meta http-equiv="refresh" content="0;URL='circuitjs.html'" /></head>
<body>This page moved to <a href="circuitjs.html">circuitjs.html</a>.</body>
</html>
EOF

retVal=$?
if [ $retVal -ne 0 ]; then
    fail
else
    sayok
fi

#--------------------------------------
# (6) Adding to .gitignore
#--------------------------------------
function fix_ignore() {
    fail
    echo -n "Adding Maven and Gradle artifacts to: .gitignore  "
    $(echo -e "\n# For Maven builds\n/target/\n" >>./.gitignore) && sayok || fail
    $(echo -e "\n# For Gradle builds\n/.gradle/\n/gradle/\n/build/\n/site/\n" >>./.gitignore) && sayok || fail
    $(echo -e "settings.gradle/\ngradlew\ngradlew.bat\n" >>./.gitignore) && sayok || fail
}

# Check .gitignore for magic string
echo -n "Checking .gitignore for Maven & Gradle items:  "
cat .gitignore |grep -E "For Gradle builds" >/dev/null && sayok || fix_ignore

#--------------------------------------
# (7) All is Good!
#--------------------------------------
echo -e "\nYour installation seem good!\nYou can now build using either Gradle or Maven."
echo "For Gradle, run:"
echo "  gradle compileGwt"
echo "  gradle makeSite"
echo "For Maven, run:"
echo "  mvn install"

echo
echo "Done!"
exit 0
# END
