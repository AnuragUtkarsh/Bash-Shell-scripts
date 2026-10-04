#!/bin/bash

trap 'echo "Someone has pressed CTRL+C";exit 1' INT

LOGFILE="/tmp/packageaudit.log"

package_audit(){
	pkg="$1"
	if rpm -q "$pkg" &>/dev/null
	then
		echo "Package: $pkg"
		installed=true
		echo "State: INSTALLED"
		installed_status=true
		echo "Version: $(rpm -q "$pkg" --queryformat '%{VERSION}-%{RELEASE}\n')"
		echo "Release: $(rpm -q "$pkg" --queryformat '%{RELEASE}')"
		echo "Architecture: $(rpm -q "$pkg" --queryformat '%{ARCH}')"
	else
		echo "Package: $pkg"
		echo "Status  : NOT INSTALLED"
		return 1
	fi

	echo -e "========================================\nLAST 10 INSTALLED PACKAGES\n========================================"
	echo "$(rpm -qa --last | head -n 10)"

        echo -e "========================================\nPACKAGE AUDIT SUMMARY\n========================================"
	echo "Total Package: $(rpm -qa | wc -l)"
	echo "Package Checked: $pkg"
	if [[ "$installed" == "true" ]]
	then
		echo "Status: INSTALLED"
	fi

	if [[ "$installed_status" == "true" ]]
	then
		echo "Audit Status: PASS"
	else
		echo "Audit Status: FAILED"
	fi
}

if [[ "$#" -ne 1 ]]
then
	echo "Usage: $0 <Package_name>"
	exit 1
fi
package_audit "$@" >> "$LOGFILE"
