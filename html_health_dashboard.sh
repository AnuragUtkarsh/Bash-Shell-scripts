#!/bin/bash

LOGFILE=/tmp/html_health.log
HTMLFILE=/tmp/health.html

trap 'echo -e "\nSomeone has pressed CTRL+C"; exit 1' INT

# ---------------- SYSTEM INFO ----------------

system_info()
{
    HOSTNAME=$(hostname)
    DATE=$(date)
    OS=$(grep '^PRETTY_NAME=' /etc/os-release | cut -d= -f2- | tr -d '"')
    KERNEL=$(uname -r)
    UPTIME=$(uptime -p)
    IP=$(hostname -I | awk '{print $1}')
}

# ---------------- CPU INFO ----------------

cpu_health()
{
    CPU_MODEL=$(lscpu | awk -F: '/^Model name:/ {gsub(/^[ \t]+/,"",$2); print $2}')
    CPU_ARCH=$(lscpu | awk -F: '/^Architecture:/ {gsub(/^[ \t]+/,"",$2); print $2}')
    CPU_CORES=$(lscpu | awk -F: '/^Core\(s\) per socket:/ {gsub(/^[ \t]+/,"",$2); print $2}')
    CPU_THREADS=$(lscpu | awk -F: '/^Thread\(s\) per core:/ {gsub(/^[ \t]+/,"",$2); print $2}')
    CPU_SOCKETS=$(lscpu | awk -F: '/^Socket\(s\):/ {gsub(/^[ \t]+/,"",$2); print $2}')

    read -r LOAD1 LOAD5 LOAD15 REST < /proc/loadavg
}

# ---------------- MEMORY INFO ----------------

memory_check()
{
    TMEMORY=$(free -m | awk 'NR==2 {print $2}')
    UMEMORY=$(free -m | awk 'NR==2 {print $3}')
    FMEMORY=$(free -m | awk 'NR==2 {print $4}')
    AMEMORY=$(free -m | awk 'NR==2 {print $7}')

    USED_PERCENTAGE=$(( UMEMORY * 100 / TMEMORY ))
    FREE_PERCENTAGE=$(( (TMEMORY - UMEMORY) * 100 / TMEMORY ))
}

# ---------------- DISK INFO ----------------

disk_check()
{
    DISK_ROWS=""

    while read -r filesystem size used avail usage mount
    do
        use_num=$(echo "$usage" | tr -d '%')

        if [[ "$use_num" -gt 90 ]]
        then
            STATUS="CRITICAL"
        elif [[ "$use_num" -ge 80 ]]
        then
            STATUS="WARNING"
        else
            STATUS="OK"
        fi

        DISK_ROWS+="<tr><td>$filesystem</td><td>$size</td><td>$used</td><td>$avail</td><td>$usage</td><td>$STATUS</td></tr>"
    done < <(df -hT | awk 'NR>1 {print $1,$3,$4,$5,$6,$7}')
}

# ---------------- LOG ----------------

write_log()
{
    {
        echo "========== HTML HEALTH REPORT =========="
        echo "Hostname: $HOSTNAME"
        echo "Date: $DATE"
        echo "Kernel: $KERNEL"
        echo "CPU: $CPU_MODEL"
        echo "Memory Used: $USED_PERCENTAGE%"
        echo "IP: $IP"
        echo "========================================"
    } >> "$LOGFILE"

    return 0
}

# ---------------- HTML GENERATION ----------------

generate_html()
{
    cat <<EOF > "$HTMLFILE"
<!DOCTYPE html>
<html>
<head>
<title>Server Health Dashboard</title>

<style>
body {
    font-family: Arial, sans-serif;
    margin: 30px;
}

h1 {
    text-align: center;
}

table {
    border-collapse: collapse;
    width: 100%;
    margin-bottom: 30px;
}

th, td {
    border: 1px solid black;
    padding: 8px;
    text-align: left;
}

th {
    background-color: #dddddd;
}
</style>

</head>

<body>

<h1>Server Health Dashboard</h1>

<h2>System Information</h2>

<table>
<tr><th>Parameter</th><th>Value</th></tr>
<tr><td>Hostname</td><td>$HOSTNAME</td></tr>
<tr><td>Date</td><td>$DATE</td></tr>
<tr><td>OS</td><td>$OS</td></tr>
<tr><td>Kernel</td><td>$KERNEL</td></tr>
<tr><td>Uptime</td><td>$UPTIME</td></tr>
<tr><td>IP Address</td><td>$IP</td></tr>
</table>


<h2>CPU Information</h2>

<table>
<tr><th>Parameter</th><th>Value</th></tr>
<tr><td>CPU Model</td><td>$CPU_MODEL</td></tr>
<tr><td>Architecture</td><td>$CPU_ARCH</td></tr>
<tr><td>CPU Cores</td><td>$CPU_CORES</td></tr>
<tr><td>CPU Threads</td><td>$CPU_THREADS</td></tr>
<tr><td>CPU Sockets</td><td>$CPU_SOCKETS</td></tr>
<tr><td>1 Minute Load</td><td>$LOAD1</td></tr>
<tr><td>5 Minute Load</td><td>$LOAD5</td></tr>
<tr><td>15 Minute Load</td><td>$LOAD15</td></tr>
</table>


<h2>Memory Information</h2>

<table>
<tr><th>Parameter</th><th>Value</th></tr>
<tr><td>Total Memory</td><td>$TMEMORY MB</td></tr>
<tr><td>Used Memory</td><td>$UMEMORY MB</td></tr>
<tr><td>Free Memory</td><td>$FMEMORY MB</td></tr>
<tr><td>Available Memory</td><td>$AMEMORY MB</td></tr>
<tr><td>Used Percentage</td><td>$USED_PERCENTAGE%</td></tr>
<tr><td>Free Percentage</td><td>$FREE_PERCENTAGE%</td></tr>
</table>


<h2>Disk Information</h2>

<table>
<tr>
<th>Filesystem</th>
<th>Size</th>
<th>Used</th>
<th>Available</th>
<th>Use%</th>
<th>Status</th>
</tr>

$DISK_ROWS

</table>


<h2>Network Information</h2>

<table>
<tr><th>Parameter</th><th>Value</th></tr>
<tr><td>IP Address</td><td>$IP</td></tr>
</table>

</body>
</html>
EOF

    return 0
}

# ---------------- MAIN ----------------

system_info
cpu_health
memory_check
disk_check
write_log
generate_html

if [[ $? -eq 0 ]]
then
    echo "HTML Health Dashboard generated successfully"
    echo "Dashboard: $HTMLFILE"
    exit 0
else
    echo "HTML Health Dashboard generation failed"
    exit 1
fi
