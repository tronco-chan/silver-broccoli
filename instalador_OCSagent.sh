#!/bin/bash

#########################################################################################################
##Script de instalación de OCS Inventory UnixAgent											                               ##
##Fecha: 23/11/2020                                                                                    ##
##Versión 1.0:  Descarga del agente e instala automáticamente. Únicamente necesario elegir el SO.      ##
##				En caso de error asegurarse de tener acceso a todos los repositorios "non-free" y similares  ##
##Autores:                                                                                             ##
##			Luis Mera Castro																		                                           ##
##			Rubén Míguez Bouzas										                                                         ##
#########################################################################################################

function comprobacionesIniciales() {
	if ! isRoot; then
		echo "El script tiene que ser ejecutado como root"
		exit 1
	fi
}

#Funcion que comprueba que se ejecute el script como root
function isRoot() {
	if [ "$EUID" -ne 0 ]; then
		return 1
	fi
	updatesinprogress
}

#comprobar que no haya instalaciones en proceso
function updatesinprogress() {
	dpkg -i /dev/zero 2>/dev/null
	if [ "$?" -eq 2 ]; then
	    echo "/var/lib/dpkg está bloqueado. Termina de actualizar tu sistema y vuelve a ejecutar el script"
	fi
	seleccionarOS
}

function instalarCENTOS() {
  #añadimos repositorio
  su -c 'rpm -Uvh https://download.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm'
  #modulos minimos
  yum install perl-XML-Simple perl-devel perl-Compress-Zlib perl-Net-IP perl-LWP perl-Digest-MD5 perl-Net-SSLeay perl-Data-UUID
  #todos los modulos recomendados
  #yum install perl-Crypt-SSLeay perl-Net-SNMP perl-Proc-Daemon perl-Proc-PID-File perl-Sys-Syslog pciutils smartmontools monitor-edid
  ejecucionINSTALL
}

function instalarDEBIAN() {
  mkdir /var/log/ocsinventoryagent-logsfolder/
  touch /var/log/ocsinventoryagent-logsfolder/ocsagent.log
  apt install -y libcrypt-ssleay-perl libnet-ssleay-perl libnet-ip-perl libnet-netmask-perl libproc-daemon-perl libdata-uuid-perl libxml-simple-perl make nmap
  apt install -y libcrypt-ssleay-perl libnet-snmp-perl libproc-pid-file-perl libproc-daemon-perl net-tools libsys-syslog-perl pciutils smartmontools read-edid nmap libnet-netmask-perl
  ejecucionINSTALL
}

function ejecucionINSTALL() {
  wget https://github.com/tronco-chan/UnixAgent/archive/v2.8.0.tar.gz
  tar -xvzf v2.8.0.tar.gz
  cd UnixAgent-2.8.0
  sudo env PERL_AUTOINSTALL=1 perl Makefile.PL && make && make install && perl postinst.pl --nowizard --server=https://ocsng.altia.es --nossl --logfile=/var/log/ocsinventoryagent-logsfolder/ocsagent.log --crontab --now
  #make
  #make install
}

function seleccionarOS() {
  echo "Que sistema operativo estás usando??"
	echo " 1. Fedora / Redhat / Centos7 y similares"
	echo " 2. Debian Stretch / Ubuntu"
  echo " 3. Ninguno, quiero salir de aqui"
  read -e CONTINUAR
  if [[ CONTINUAR  -eq 1 ]]; then
  		instalarCENTOS
  elif [[ CONTINUAR -eq 2 ]]; then
  		instalarDEBIAN
  elif [[ CONTINUAR -eq 3 ]]; then
  		echo "Hasta la próxima!"
  		exit 1
  fi
}

comprobacionesIniciales
