#!/bin/bash

set -euv -o pipefail
cd "`dirname $0`/.."

# See https://github.com/JuliaCI/BenchmarkTools.jl/blob/master/doc/linuxtips.md#introduction
# for an explanation of these configuration options

sudo apt update
sudo apt install build-essential libatomic1 python3 gfortran perl wget m4 cmake pkg-config curl ninja-build ccache
sudo apt install virtualenv
virtualenv cset

[ -d julia-1.5.3 ] || curl -fL https://julialang-s3.julialang.org/bin/linux/x64/1.5/julia-1.5.3-linux-x86_64.tar.gz | tar xz
[ -d PkgEval.jl ] || git clone git@github.com:JuliaCI/PkgEval.jl.git

sudo ln -f "`dirname $0`/sysctl.conf" /etc/sysctl.d/99-nanosoldier.conf
sudo service procps force-reload
# echo "performance" | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
# echo 0 | sudo tee /sys/devices/system/cpu/cpufreq/boost

# echo 0 | sudo tee /sys/devices/system/cpu/cpu{8..15}/online
(cd /sys/devices/system/cpu &&
for cpu in {0..255}; do
    if [ -f cpu$cpu/topology/thread_siblings_list ]; then
        for other in `sed -e 's/,/ /' < cpu$cpu/topology/thread_siblings_list`; do
            [ $other == $cpu ] && continue
            echo "disabling cpu $other (shared with $cpu)"
            echo 0 | sudo tee /sys/devices/system/cpu/cpu$other/online > /dev/null
        done
    fi
done)

echo "informational status:"
cat /proc/interrupts
# echo 0-2 | sudo tee /proc/irq/22/smp_affinity_list
# irqbalance

[ -f ~/.ssh/id_rsa.pub ] || ssh-keygen
git config --global user.name "nanosoldier"
git config --global user.email "nanosoldierjulia@gmail.com"

# TODO: use this (non-privileged) user to run the build and test:
sudo useradd nanosoldier || true

set +v

echo "manual steps:"
echo
echo "install this ssh key in github for user @nanosoldier"
echo "https://github.com/settings/ssh/new"
cat ~/.ssh/id_rsa.pub
echo
echo "and generate an auth-token for later"
echo "https://github.com/settings/tokens/new"
echo "scopes: 'repo' (all), 'notifications'"
echo
echo "install this webhook in github"
echo "https://github.com/JuliaLang/julia/settings/hooks"
echo "url: http://<this-ip>:<random-port>"
echo "content-type: application/json"
echo "secret: <random-string>"
echo "events: 'Commit comments', 'Issue comments', 'Pull request review comments'"
echo
echo "firewall configuration:"
echo "ensure TCP <random-port> is not blocked"
echo "ensure ssh (TCP 22) is not blocked for your ip address"
echo "ensure all other ports are blocked"
echo
echo "these special values, you will insert into env."
echo "to use, as user 'nanosoldier':"
echo "cd `dirname $0`"
echo "export GITHUB_AUTH=<auth-token>"
echo "export GITHUB_SECRET=<random-string>"
echo "export GITHUB_PORT=<random-port>"
echo "export JULIA_PROJECT=`dirname $0`"
echo ". ../cset/bin/activate"
echo "setarch -R ~/julia-1.5.3/bin/julia -L bin/setup_base_ci.jl -e 'using Sockets; run(server, IPv4(0), GITHUB_PORT)'"
echo
