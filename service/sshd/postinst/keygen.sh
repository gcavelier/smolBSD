# taken from NetBSD's /etc/rc.d/sshd
keygen="/usr/bin/ssh-keygen"
umask 022
new_key_created=false
while read type bits filename;  do
	f="etc/ssh/$filename"
	case "${bits}" in
	-1)     bitarg=;;
	0)      bitarg="${ssh_keygen_flags}";;
	*)      bitarg="-b ${bits}";;
	esac
	"${keygen}" -t "${type}" ${bitarg} -f "${f}" -N '' -q && \
	    printf "ssh-keygen: " && "${keygen}" -f "${f}" -l
	new_key_created=true
done << _EOF
ecdsa   -1      ssh_host_ecdsa_key
ed25519 -1      ssh_host_ed25519_key
rsa     0       ssh_host_rsa_key
_EOF
# we want sshd to be the main process
echo 'sshd_flags="-D -e"' >> etc/rc.conf
echo 'UseDNS no' >> etc/ssh/sshd_config
sed -i'' 's/^UsePAM/# UsePAM/' etc/ssh/sshd_config

ssh-add -L >etc/ssh/authorized_keys
pubkeys="../service/sshd/etc/*.pub"
ls $pubkeys >/dev/null 2>&1 && \
	cat $pubkeys >>etc/ssh/authorized_keys

mkdir -p home var/cache
