#!/bin/bash
	#########################################################################################################
	##Script de instalación de ELK (Elasticsearch, Kibana, Logstash y Filebeat)                            ##
	##Fecha: 26/10/2020                                                                                    ##
	##Versión 1.0:  Permite la instalacion simple de todos los programas antes indicados                   ##
	##				Si la instalación de todos los componentes se hace en una misma máquina                      ##
	##				queda una versión completamente operativa. Si se instala en diferentes máquinas              ##
	##				es necesario modificar la configuración manualmente.                                         ##
	##Autores:                                                                                             ##
	##			Luis Mera Castro																		                                           ##
	##			Rubén Míguez Bouzas										                                                         ##
	#########################################################################################################

	#Almacenamos el directorio actual en la variable PWD
	PWD=$(pwd)

	#Almacenamos en una variable si queremos una instalación local o distribuida
	Instalacion_Local='SI'
	#Almacenamos en variables globales las distintas IP y puertos para las configuraciones
	Puerto_Elasticsearch=''
	IP_Elasticsearch=''

	Puerto_Kibana=''
	IP_Kibana=''

	Puerto_Logstash=''
	IP_Logstash=''

	#Funcion que comprueba que se ejecute el script como root
	function isRoot() {
		if [ "$EUID" -ne 0 ]; then
			return 1
		fi
		checkOS
	}

	#Comprobación inicial que valida si se es root y si el sistema operativo es Ubutu
	function comprobacionesIniciales() {
		if ! isRoot; then
			echo "El script tiene que ser ejecutado como root"
			exit 1
		fi
	}

	function checkOS() {
		source /etc/os-release
		if [[ $ID == "ubuntu" ]]; then
				OS="ubuntu"
				MAJOR_UBUNTU_VERSION=$(echo "$VERSION_ID" | cut -d '.' -f1)
				if [[ $MAJOR_UBUNTU_VERSION -lt 16 ]]; then
					echo "⚠️ Este script no está probado en tu versión de Ubuntu. ¿Deseas continuar?"
					echo ""
					CONTINUAR = 'false'
					until [[ $CONTINUAR =~ (y|n) ]]; do
						read -rp "Continuar? [y/n]: " -e CONTINUAR
					done
					if [[ $CONTINUAR == "n" ]]; then
						exit 1
					fi
				fi
			preguntasInstalacion
		fi

	}


	function anadirClavePGP() {
		echo "Comprobando claves PGP de elasttic"
		if apt-key list | grep -q "elastic"; then
			echo "Claves PGP correctamente configuradas"
		else
			echo "Claves PGP no configuradas, se añaden"
			wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
		fi
	}

	function anadirPaqueteTransport(){
		echo "Comprobando instalación del paquete apt-transport-https"
		if dpkg -s | grep "apt-transport-https" > /dev/null; then
			echo "Paquete ya instalado"
		else
			echo "Paquete no instalado. Se instala"
			sudo apt install apt-transport-https
		fi
	}

	function andirRepositorios() {
		if ls /etc/apt/sources.list.d | grep elastic > /dev/null; then
			echo "Ya tienes configurados los repositorios de elastic"
		else
			echo "Añadiendo a repositorio"
			echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-7.x.list
		fi
	}


	function modificarSeguridadElastic(){
		echo "Quieres habilitar la seguridad avanzada en elastic? (gestión de usuarios en Kibana) [y/n]"
		echo "De ser así, se modificarán las contraseñas de los usuarios predeterminados:"
		CONTINUAR='false'
		read -e CONTINUAR
		if [[ CONTINUAR =~ 'y' ]]; then
			echo "Se habilita xpack.security"
			cp /etc/elasticsearch/elasticsearch.yml /etc/elasticsearch/elasticsearch.yml.backup$(date +%d)
			echo "xpack.security.systemctl enabled: true" >> /etc/elasticsearch/elasticsearch.yml
			echo "Se inicia Elasticsearch para proceder al cambio de contraseñas"
			systemctl restart elasticsearch.service
			read -e MODOCONTRASENAS
			if [[ MODOCONTRASENAS == 1 ]]; then
				echo "Se habilita el modo interactivo."
				echo " Se te solicitará que introduzcas las contraseñas manualmente"
				echo "Las contraseñas generadas se almacenarán en $PWD"
				cd usr/share/elasticsearch/bin
				./elasticsearch-setup-passwords interactive 2>&1 | tee $PWD/ficheroContrasenas.txt
				echo "Recuerda cambiar estas contraseñas en los ficheros:"
				echo "de Kibana --> /etc/kibana/kibana.yml"
				echo "de Logstash --> /etc/logstash/logstash.yml"
				echo "de filebeat --> /etc/filebeat/filebeat.yml"
				cd $PWD
			else
				echo "Se habilita el modo automático. Las contraseñas generadas se almacenarán en $PWD"
				cd usr/share/elasticsearch/bin
				./elasticsearch-setup-passwords auto 2>&1 | tee $PWD/ficheroContrasenas.txt
				echo "Recuerda cambiar estas contraseñas en los ficheros:"
				echo "de Kibana --> /etc/kibana/kibana.yml"
				echo "de Logstash --> /etc/logstash/logstash.yml"
				echo "de filebeat --> /etc/filebeat/filebeat.yml"
				cd $PWD
			fi
		fi
	}

	function instalarJava(){
		if dpkg -l | grep java > /dev/null; then
			echo "Java ya está instalado en tu sistema."
			echo "No se continúa con la instalación"
		else
			apt install openjdk-8-jre-headless
		fi
	}

	function instalarElasticsearch(){
		anadirClavePGP
		anadirPaqueteTransport
		andirRepositorios
		if dpkg -l | grep elastic > /dev/null; then
			echo "Elasticsearch ya está instalado en tu sistema."
			echo "No se continúa con la instalación"
		else
			apt update && apt install elasticsearch
			cp /etc/elasticsearch/elasticsearch.yml /etc/elasticsearch/elasticsearch.yml.backup$(date +%d)
			systemctl daemon-reload
			systemctl enable elasticsearch.service
			CONTINUAR='false'
			until [[ $CONTINUAR =~ (y|n) ]]; do
				read -rp "Deseas cambiar la IP de elascticsearch (por defecto localhost)? [y/n]: " -e CONTINUAR
				done
				if [[ $CONTINUAR =~ 'y' ]]; then
					IP_Elasticsearch='NoDefinida'
					echo "$IP_Elasticsearch"
					until [[ $IP_Elasticsearch =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; do
						read -rp "Introduce una IP válida  --> " -e IP_Elasticsearch
					done
					sed -i "s|#network.host: 192.168.0.1$|network.host: $IP_Elasticsearch|" /etc/elasticsearch/elasticsearch.yml
					sed -i "s|#|discovery.seed_hosts: ["127.0.0.1", "\[::1\]"\]|"
				elif [[ $CONTINUAR =~ 'n' ]]; then
					echo "Se continua la instalación con los valores predeterminados"
				fi
			CONTINUAR='false'
			until [[ $CONTINUAR =~ (y|n) ]]; do
				read -rp "Deseas cambiar el puerto HTTP (por defecto 9200)? [y/n]: " -e CONTINUAR
			done
			if [[ CONTINUAR =~ 'y' ]]; then
				Puerto_Elasticsearch='NoDefinido'
				until [[ $Puerto_Elasticsearch =~ ^[0-9]{0,5}$ ]]; do
					read -rp "Introduce un puerto válido --> " -e Puerto_Elasticsearch
				done
				sed -i "s|#http.port: 9200$|http.port: $Puerto_Elasticsearch|" /etc/elasticsearch/elasticsearch.yml
			elif [[ CONTINUAR =~ 'n' ]]; then
					echo "Se continua la instalación con los valores predeterminados"
			fi
			modificarSeguridadElastic
			echo "Se ha instalado Elasticsearch y se ha habilitado en System-D"
			echo "Para iniciar/parar el servicio basta con utilizar"
			echo "systemctl [start | stop] elasticsearch.service"
			echo "Esta vez ya se inicia automaticamente. Espera unos instantes..."
			systemctl start elasticsearch.service
		fi
	}

	function instalarKibana(){
		anadirClavePGP
		anadirPaqueteTransport
		andirRepositorios
		if dpkg -l | grep kibana > /dev/null; then
			echo "Kibana ya está instalado en tu sistema."
			echo "No se continúa con la instalación"
		else
			apt update && apt install kibana
			cp /etc/kibana/kibana.yml /etc/kibana/kibana.yml.backup$(date +%d)
			sudo systemctl daemon-reload
			sudo systemctl enable kibana.service
			if [[ $IP_Elasticsearch -ne '' ]]; then
				echo "Se modifica la configuración de kibana para que apunte a la IP y puertos indicados para Elasticsearch"
				sed -i "s|#elasticsearch.hosts: [\"http://localhost:9200\"]$|elasticsearch.hosts: [\"http://IP_Elasticsearch:Puerto_Elasticsearch\"]|" /etc/kibana/kibana.yml
			fi
			echo "Se ha instalado kibana y se ha habilitado en System-D"
			echo "Para iniciar/parar el servicio basta con utilizar"
			echo "systemctl [start | stop] elasticsearch.service"
			systemctl start kibana.service
		fi
	}

		function instalarLogstash(){
		anadirClavePGP
		anadirPaqueteTransport
		andirRepositorios
		if dpkg -l | grep logstash > /dev/null; then
			echo "logstash ya está instalado en tu sistema."
			echo "No se continúa con la instalación"
		else
			apt update && apt install logstash
			cp /etc/logstash/logstash.yml /etc/logstash/logstash.yml.backup$(date +%d)
			systemctl daemon-reload
			systemctl enable logstash.service
			if [[ $IP_Elasticsearch -ne '' ]]; then
				echo "Se modifica la configuración de kibana para que apunte a la IP y puertos indicados para Elasticsearch"
				sed -i "s|#elasticsearch.hosts: [\"http://localhost:9200\"]$|elasticsearch.hosts: [\"http://$IP_Elasticsearch:$Puerto_Elasticsearch\"]|" /etc/kibana/kibana.yml
			fi
			echo "Se ha instalado Logstash y se ha habilitado en System-D"
			echo "Para iniciar/parar el servicio basta con utilizar"
			echo "systemctl [start | stop] logstash.service"
			systemctl start logstash.service
		fi
	}

		function instalarFilebeat(){
			anadirClavePGP
			anadirPaqueteTransport
			andirRepositorios
			if dpkg -l | grep filebeat > /dev/null; then
				echo "Filebeat ya está instalado en tu sistema."
				echo "No se continúa con la instalación"
			else
				apt update && apt install filebeat
				cp /etc/filebeat/filebeat.yml /etc/filebeat/filebeat.yml.backup$(date +%d)
				sudo systemctl daemon-reload
				sudo systemctl enable filebeat.service
				echo "Se ha instalado filebeat y se ha habilitado en System-D"
				echo "Para iniciar/parar el servicio basta con utilizar"
				echo "systemctl [start | stop] filebeat.service"
				echo "A modo prueba se va a instalar el módulo System de filebeat para monitorizar el sistema"
				filebeat modules enable system
				filebeat setup
				echo "Para continuar la configuración, es necesario editar manualmente el fichero:"
				echo "sudo nano /etc/filebeat/filebeat.yml"
				systemctl start filebeat.service
			fi
		}

	function desinstalarKibana() {
		apt purge kibana
		ELIMINARFICHEROS='false'
		until [[ $ELIMINARFICHEROS =~ (y|n) ]]; do
			read -rp "Eliminar ficheros de datos de Kibana /var/lib? [y/n]: " -e ELIMINARFICHEROS
		done
		if [[ $ELIMINARFICHEROS == "y" ]]; then
			rm -rf /var/lib/kibana
		else
			continue
		fi
	}

	function desinstalarLogstash() {
		apt purge logstash
		ELIMINARFICHEROS='false'
		until [[ $ELIMINARFICHEROS =~ (y|n) ]]; do
		read -rp "Eliminar ficheros de datos de LogsStash /var/lib? [y/n]: " -e ELIMINARFICHEROS
		done
		if [[ $ELIMINARFICHEROS == "y" ]]; then
			rm -rf /var/lib/logstash
		else
			continue
		fi
	}

	function desinstalarElasticsearch() {
 		apt purge elasticsearch
 		ELIMINARFICHEROS='false'
		until [[ $ELIMINARFICHEROS =~ (y|n) ]]; do
		read -rp "Eliminar ficheros de datos de Elasticsearch en/var/lib? [y/n]: " -e ELIMINARFICHEROS
		done
		if [[ $ELIMINARFICHEROS == "y" ]]; then
			rm -rf /var/lib/elasticsearch
		else
			continue
		fi
	}

	function desinstalarFilebeat() {
		apt purge filebeat
 		ELIMINARFICHEROS='false'
		until [[ $ELIMINARFICHEROS =~ (y|n) ]]; do
		read -rp "Eliminar ficheros de datos de Filebeat /var/lib? [y/n]: " -e ELIMINARFICHEROS
		done
		if [[ $ELIMINARFICHEROS == "y" ]]; then
			rm -rf /var/lib/filbeat
		else
			continue
		fi
	}

	function instalarELK() {
		instalarJava
		instalarKibana
		instalarElasticsearch
		instalarLogstash
		instalarFilebeat
	}

	function preguntasInstalacion(){
		echo -e "\e[92mQué deseas instalar?"
		echo "1. Suite ELK"
		echo "2. Kibana"
		echo "3. Elasticsearch"
		echo "4. Logstash"
		echo "5. filebeat"
		echo "6. Java"
		echo -e "\e[33m7. Salir de la instalación"
		echo -e "\e[31m8. Desinstalar todo (Elasticsearch, kibana, logstash, filebeat)"
		echo "9. Desinstalar Elasticsearch"
		echo "10. Desinstalar kibana"
		echo "11. Desinstalar logstash"
		echo "12. Desinstalar filebeat"
		echo -e "\e[92m"
		read -e CONTINUAR
		if [[ CONTINUAR  -eq 1 ]]; then
			instalarELK
		elif [[ CONTINUAR -eq 2 ]]; then
			instalarKibana
		elif [[ CONTINUAR -eq 3 ]]; then
			instalarElasticsearch
		elif [[ CONTINUAR -eq 4 ]]; then
			instalarLogstash
		elif [[ CONTINUAR -eq 5 ]]; then
			instalarfilebeat
		elif [[ CONTINUAR -eq 6 ]]; then
			instalarJava
		elif [[ CONTINUAR -eq 7 ]] ; then
			echo "Hasta la próxima!"
			exit 1
		elif [[ CONTINUAR -eq 9 ]] ; then
			echo "Se desinstala Elasticsearch"
			desinstalarElasticsearch
		elif [[ CONTINUAR -eq 10 ]] ; then
			echo "Se desinstala Kibana"
			desinstalarKibana
		elif [[ CONTINUAR -eq 11 ]] ; then
			echo "Se desinstala Logstash"
			desinstalarLogstash
		elif [[ CONTINUAR -eq 12 ]] ; then
			echo "Se desinstala Filebeat"
			desinstalarFilebeat
		elif [[ CONTINUAR -eq 8 ]] ; then
			echo "Se desinstalan todas las aplicaciones"
			echo "Desinstalar Kibana"
			desinstalarKibana
			echo "Desinstalar Logstash"
			desinstalarLogstash
			echo "Desinstalar Elasticsearch"
			desinstalarElasticsearch
			echo "Desinstalar filebeat"
			desinstalarFilebeat
		else
			echo "Opcion no válida!"
			preguntasInstalacion
		fi
	}

	comprobacionesIniciales