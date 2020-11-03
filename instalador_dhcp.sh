#!/bin/bash
#Almacenamos el directorio actual en la variable PWD
PWD=$(pwd)
#Almacenamos la variable de sistema operativo en usamos
OS=""

#Comprobación inicial que valida si se es root y que sistema operativo usamos
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
	checkOS
}

#Funcion que verifica el sistema operativo en uso
function checkOS() {
	if [[ -e /etc/debian_version ]]; then
		OS="debian"
		source /etc/os-release

		if [[ $ID == "debian" || $ID == "raspbian" ]]; then
			if [[ $VERSION_ID -gt 9 ]]; then
				echo "⚠️ Tu version de Debian es posterior a la creacion de este script."
				echo ""
				echo "Puedes continuar, pero es posible que haya cambiado alguna configuracion"
				echo "y el fichero generado ya no sea válido."
				echo ""
				until [[ $CONTINUE =~ (y|n) ]]; do
					read -rp "Continue? [y/n]: " -e CONTINUE
				done
				if [[ $CONTINUE == "n" ]]; then
					exit 1
				fi
			fi
		elif [[ $ID == "ubuntu" ]]; then
			OS="ubuntu"
			MAJOR_UBUNTU_VERSION=$(echo "$VERSION_ID" | cut -d '.' -f1)
			if [[ $MAJOR_UBUNTU_VERSION -gt 20 ]]; then
				echo "⚠️ Tu version de Ubuntu es posterior a la creacion de este script."
				echo ""
				echo "Puedes continuar, pero es posible que haya cambiado alguna configuracion"
				echo "y el fichero generado ya no sea válido."
				echo ""
				until [[ $CONTINUE =~ (y|n) ]]; do
					read -rp "Continue? [y/n]: " -e CONTINUE
				done
				if [[ $CONTINUE == "n" ]]; then
					exit 1
				fi
			fi
			preguntasInstalacion
		fi
	elif [[ -e /etc/system-release ]]; then
		source /etc/os-release
		if [[ $ID == "fedora" ]]; then
			OS="fedora"
		fi
		if [[ $ID == "centos" ]]; then
			OS="centos"
			if [[ $VERSION_ID -gt 8 ]]; then
				echo "⚠️ Tu version de Centos es posterior a la creacion de este script."
				echo ""
				echo "Puedes continuar, pero es posible que haya cambiado alguna configuracion"
				echo "y el fichero generado ya no sea válido."
				echo ""
				until [[ $CONTINUE =~ (y|n) ]]; do
					read -rp "Continue? [y/n]: " -e CONTINUE
				done
				if [[ $CONTINUE == "n" ]]; then
					exit 1
				fi
			fi
		fi
	elif [[ -e /etc/arch-release ]]; then
		OS="arch"
	else
		echo "Estas ejecutando este instalador en un OS distinto a Debian, Ubuntu, Fedora, CentOS, Amazon Linux 2 or Arch Linux system"
		exit 1
	fi
}




function comprobarInstalado_dpkg() {
	if dpkg -l | grep isc-dhcp-server > /dev/null; then
		echo "ISC DHCP Server ya está instalado en tu sistema."
		echo "No se continúa con la instalación."
		preguntasInstalacion
	#else
		#continue
	fi
}

function instalarDHCP() {
	if [ $OS = "ubuntu" ] || [ $OS = "debian" ]; then
		comprobarInstalado_dpkg
		apt update && apt install isc-dhcp-server
		cp /etc/dhcp/dhcpd.conf "/etc/dhcp/dhcpd.conf.original$(date +%d)"
		echo "Instalacion finalizada! Recuerda modificar /etc/default/isc-dhcp-server"
		echo "\e[1;33mEs necesario definir la interfaz en la que trabajara DHCP server.\e[0m"
	elif [ $OS = "centos" ]; then
		#comprobarinstlado
		#yum makecache
		yum -y install dhcp
		cp /etc/dhcp/dhcpd.conf "/etc/dhcp/dhcpd.conf.backup$(date +%d%h)"
		echo "Instalacion finalizada! Recuerda modificar /etc/sysconfig/dhcpd"
		echo "\e[1;33mEs necesario definir la interfaz en la que trabajara DHCP server.\e[0m"
	elif [ $OS = "fedora" ]; then
		#asdf
		echo " prueba"
	elif [ $OS = "arch" ]; then
		#asd
		echo "prueba2"
	fi
}





function configurarCONF() {
	cp /etc/dhcp/dhcpd.conf "/etc/dhcp/dhcpd.conf.backup$(date +%d)"

	echo "Vamos a generar el fichero de configuracion dhcpd.conf."
	echo "En primer lugar vamos a definir opciones globales que aplicaran a todas las subnets."

	read -rp "El servidor DHCP es autoritativo? Si es el único en la red, selecciona si. (y/n): " autoritativosino
	if [ "$autoritativosino" != "${autoritativosino#[Yy]}" ]; then
  	autoritativo="authoritative;"
	else
  	autoritativo="#authoritative"
	fi
	#echo $autoritativo #debug

	read -rp "La red tiene tiene un controlador de dominio? y/n: " dominiosino
	echo $dominiosino
	if [ "$dominiosino" != "${dominiosino#[Yy]}" ]; then
  	read -rp "Introduce el nombre de dominio: " dominio
	fi

	echo "Vamos a configurar los servidores DNS."
	read -rp 'Introduce la lista de DNS, separados por ", ": ' dns
	############
	#read -rp "Introduce la ip del servidor DNS principal:" dns1
	#while true;
	#do
	#	read -r -P "Deseas introducir más DNS? (y/n)" response
	#	if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]]; then
  #    echo "Introduce el siguiente servidor DNS: " dns2
  #	else
  #    exit 0
  #	fi
	#done

	echo "Deseas cambiar el tiempo de duracion de las concesiones? (y/n)"
	read -rp "Por defecto default=600 y max=7200 " concesionessino
	if [ "$concesionessino" != "${concesionessino#[Yy]}" ]; then
  	read -rp "Introduce default-lease-time (en segundos): " defaultleasetime
		read -rp "Introduce max-lease-time (en segundos): " maxleasetime
	fi

	echo "Vamos a definir las subredes."

	subnet0

	escribirCONF
}


function subnet0() {
	echo "Empecemos con la red principal."
	read -rp "Indica la ip de la subnet (por ej 192.168.0.0): " subnet0ip
	read -rp "Indica la mascara de red (255.255.0.0): " subnet0netmask
	#read $subnet0ip
	valoresEspecificossubnet0
	read -rp "Indica el rango de IP inicial" subnet0ipinicial
	read -rp "indica el rango de IP final" subnet0ipfinal

}

function valoresEspecificossubnet0() {
	read -rp "Deseas añadir algun campo especifico a esta subred?" valoresespecifsunet0sino
	if [ "$valoresespecifsunet0sino" != "${valoresespecifsunet0sino#[Yy]}" ]; then
		#echo "a"
		read -rp "Deseas añadirle option routers?" nombrevariablesino
		read -rp "Deseas añadirle option domain-name?" nombrevariablesino
	else
		CONTINUE
	fi

}


function escribirCONF() {
	echo "################################################################################################" > /etc/dhcp/dhcpd.conf
	echo "################################################################################################" >> /etc/dhcp/dhcpd.conf
	echo "#########                    Fichero generado con Instalador_DHCP.sh                   #########" >> /etc/dhcp/dhcpd.conf
	echo "################################################################################################" >> /etc/dhcp/dhcpd.conf
	echo "################################################################################################" >> /etc/dhcp/dhcpd.conf
	echo "" >> /etc/dhcp/dhcpd.conf
	echo "" >> /etc/dhcp/dhcpd.conf

	echo "### OPCIONES GLOBALES ###" >> /etc/dhcp/dhcpd.conf

	echo "## Servidor autoritativo ##" >> /etc/dhcp/dhcpd.conf
	echo "#En caso de que este DHCP pase a ser el único de la red, descomentar la siguiente linea" >> /etc/dhcp/dhcpd.conf
	echo $autoritativo  >> /etc/dhcp/dhcpd.conf

	echo "## Configuracion de logs ##" >> /etc/dhcp/dhcpd.conf
	echo "log-facility local7;" >> /etc/dhcp/dhcpd.conf
	mkdir /var/log/dhcpd
	echo "local7.debug /var/log/dhcpd/dhcpd.log" >> /etc/rsyslog.conf
	rsyslogd -N1

	if [ -n "$dominio" ]; then
		echo "## Sufijo dns dominio ##" >> /etc/dhcp/dhcpd.conf
		echo 'option domain-name ' \"$dominio\"';' >> /etc/dhcp/dhcpd.conf
	else
		CONTINUE
	fi

	echo "## Lista de DNS ##" >> /etc/dhcp/dhcpd.conf
	echo "option domain-name-servers " $dns ";" >> /etc/dhcp/dhcpd.conf

	echo "## Duracion concesiones dhcp ##" >> /etc/dhcp/dhcpd.conf
	echo "default-lease-time " $defaultleasetime";" >> /etc/dhcp/dhcpd.conf
	echo "max-lease-time " $maxleasetime";" >> /etc/dhcp/dhcpd.conf

	echo "## Vamos a definir la subnet principal ##"
	echo "subnet " $subnet0ip " netmask " $subnet0netmask " {" >> /etc/dhcp/dhcpd.conf
	echo "range " $subnet0ipinicial " " $subnet0ipfinal";"
	if [ "$valoresespecifsunet0sino" = "${valoresespecifsunet0sino#[Yy]}" ]; then
		echo "loquesea"
	else
		CONTINUE
	fi
	echo "}"


}




function desinstalarDHCP() {
	if [ $OS = "ubuntu" ] || [ $OS = "debian" ]; then
		apt remove isc-dhcp-server
	elif [ $OS = "centos" ]; then
		yum remove dhcp
	elif [ $OS = "fedora" ]; then
		echo "prueba"
	elif [ $OS = "arch" ]; then
		echo "prueba"
	fi
}



function preguntasInstalacion() {
	echo -e "\e[92mQué deseas hacer?"
	echo " 1. Instalar ISC-DHCP-SERVER"
	echo " 2. Generar fichero configuracion (dhcpd.conf)"
	echo -e "\e[33m 3. Salir de la instalacion"
	echo -e "\e[31m 4. Desinstalar ISC-DHCP-SERVER"
	echo -e "\e[92m"
	read -e CONTINUAR
	if [[ CONTINUAR  -eq 1 ]]; then
		instalarDHCP
	elif [[ CONTINUAR -eq 2 ]]; then
		configurarCONF
	elif [[ CONTINUAR -eq 3 ]]; then
		echo "Hasta la próxima!"
		exit 1
	elif [[ CONTINUAR -eq 4 ]]; then
		desinstalarDHCP
	else
		echo "Opcion no válida!"
		preguntasInstalacion
	fi
}

comprobacionesIniciales
