function execute_gradlew {
	if [ -e ../gradlew ]
	then
		../gradlew ${@}
	elif [ -e ../../gradlew ]
	then
		../../gradlew ${@}
	elif [ -e ../../../gradlew ]
	then
		../../../gradlew ${@}
	elif [ -e ../../../../gradlew ]
	then
		../../../../gradlew ${@}
	elif [ -e ../../../../../gradlew ]
	then
		../../../../../gradlew ${@}
	elif [ -e ../../../../../../gradlew ]
	then
		../../../../../../gradlew ${@}
	elif [ -e ../../../../../../../gradlew ]
	then
		../../../../../../../gradlew ${@}
	elif [ -e ../../../../../../../../gradlew ]
	then
		../../../../../../../../gradlew ${@}
	elif [ -e ../../../../../../../../../gradlew ]
	then
		../../../../../../../../../gradlew ${@}
	else
		echo "Unable to find locate Gradle wrapper."
	fi
}

function gw {
	execute_gradlew "${@//\//:}" --daemon
}

while getopts "e:v:k:h" flag; do
	case "$flag" in
		e) ENV_NAME=${OPTARG};;
		v) RELEASE_VERSION=${OPTARG};;
		k) DXP_ACTIVATION_KEY_DIR=${OPTARG};;
		h) echo -e "Spinner Arguments: \n -e environment_name | default: e5a2prd  \n -v release_version | default: next (latest release) \n -k dxp_activation_key | default: ~/dev/projects/dxp-activation-key/." ;;
		?) echo -e "Spinner Arguments: \n -e environment_name | default: e5a2prd  \n -v release_version | default: next (latest release) \n -k dxp_activation_key | default: ~/dev/projects/dxp-activation-key/." ;;
	esac
done

OPTION=${@:$OPTIND:1}

if [ "$OPTION" == "" ]
then
	echo "No arguments supplied"
elif [ $OPTION == "build" ]; then
	echo "spinner $OPTION"
	ENV_NAME=${ENV_NAME:-e5a2preprod}
	RELEASE_VERSION=${RELEASE_VERSION:-u102}
	DXP_ACTIVATION_KEY_DIR=${DXP_ACTIVATION_KEY_DIR:-~/dev/projects/dxp-activation-key/.}
	
	echo "";
	echo "LXC Environment Name: $ENV_NAME";
	echo "7.4 Release Version: $RELEASE_VERSION";
	echo "DXP Activation Key: $DXP_ACTIVATION_KEY_DIR";
	echo "";

	## Build Spinner
	## create or update liferay-docker
	LIFERAY_DOCKER_DIR=~/dev/projects/liferay-docker
	LIFERAY_DOCKER_REMOTE=git@github.com:liferay/liferay-docker.git

	if [ ! -d "~/dev/projects" ] ; then
		cd ~/
		mkdir dev/projects >/dev/null
	fi

	if [ ! -d "$LIFERAY_DOCKER_DIR" ] ; then
		git clone $LIFERAY_DOCKER_REMOTE $LIFERAY_DOCKER_DIR >/dev/null
		cd $LIFERAY_DOCKER_DIR
		git pull 
		git checkout master
		git rm .gitattributes >/dev/null
		git add -A
		git reset --hard

	else
		cd $LIFERAY_DOCKER_DIR
		git pull 
		git checkout master
		git rm .gitattributes >/dev/null
		git add -A
		git reset --hard
	fi
	printf '\n'
	## create or  update liferay-lxc
	LIFERAY_LXC_DIR=~/dev/projects/liferay-lxc
	LIFERAY_LXC_REMOTE=git@github.com:liferay/liferay-lxc.git

	if [ ! -d "$LIFERAY_LXC_DIR" ] ; then
		git clone $LIFERAY_LXC_REMOTE $LIFERAY_LXC_DIR >/dev/null
		cd $LIFERAY_LXC_DIR 
		git pull 
		git checkout 7.4-$RELEASE_VERSION
		git rm .gitattributes >/dev/null
		git add -A
		git reset --hard >/dev/null

	else
		cd $LIFERAY_LXC_DIR
		git pull 
		git checkout 7.4-$RELEASE_VERSION
		git rm .gitattributes >/dev/null
		git add -A
		git reset --hard >/dev/null
	fi
	
	## stop and remov	e all dockers with env name
	docker rm $(docker stop $(docker ps -a -q --filter="name=env-$ENV_NAME*") -t 2)
	## copy dxp-activation-key to spinner directory
	rsync -avz $DXP_ACTIVATION_KEY_DIR ~/dev/projects/liferay-docker/spinner/dxp-activation-key 
	##	remove old cluster dir
	cd ~/dev/projects/liferay-docker/spinner
	find . -name "env-*" -type d -prune -exec rm -rf '{}' +
	## build spinner 
	./build.sh $ENV_NAME
	cd ~/dev/projects/liferay-docker/spinner/env-$ENV_NAME*/
	## create spinner dockers
	docker compose up -d antivirus database search && docker compose up liferay-1	

elif [ $OPTION == "start" ]; then
	echo "spinner $OPTION"
	cd ~/dev/projects/liferay-docker/spinner/env-$ENV_NAME*/
	docker compose start
	printf '\n'
	printf "Starting spinner..."
    sleep .5
    printf '.'
    sleep .5
    printf '.'
    sleep .5
    printf '.'
    sleep .5
    printf '\n'

	LIFERAY_ID=$(docker ps -a -q --filter="publish=18080")
	docker logs -f $LIFERAY_ID

elif [ $OPTION == "stop"  ]; then
	echo "spinner $OPTION"
	cd ~/dev/projects/liferay-docker/spinner/env-$ENV_NAME*/
	docker compose stop

elif [ $OPTION == "deployMP"	]; then
	sleep .5
    echo 'deploying workspace directorie to gradle.proprieties.'
	echo '.'
	workspace_path=~/dev/projects/liferay-portal/workspaces/liferay-marketplace-workspace

	gradle_properties_file=$workspace_path/gradle.properties
	line_to_add="liferay.workspace.home.dir=/home/me/dev/bundles/master"

	if [ -e $gradle_properties_file ]; then
		if grep -qF "$line_to_add" $gradle_properties_file; then
			echo "Line already exists in gradle.properties. No action needed."
		else
			echo "" >> $gradle_properties_file
			echo "$line_to_add" >> $gradle_properties_file
			echo "Line added to gradle.properties."
		fi
	else
		echo "gradle.properties file not found in the specified directory."
	fi

	gw deploy


elif [ $OPTION == "restart"  ]; then
	echo "spinner $OPTION"
	cd ~/dev/projects/liferay-docker/spinner/env-$ENV_NAME*/
	docker compose restart
	printf '\n'
	printf "Starting spinner..."
    sleep .5
    printf '.'
    sleep .5
    printf '.'
    sleep .5
    printf '.'
    sleep .5
    printf '\n'

	LIFERAY_ID=$(docker ps -a -q --filter="publish=18080")
	docker logs -f $LIFERAY_ID

elif [ $OPTION == "rm"  ]; then
	echo "spinner $OPTION"
	docker rm $(docker ps -a -q --filter="name=env-$ENV_NAME*")

elif [ $OPTION == "forceDeploy"  ]; then
	echo "spinner $OPTION"
	LIFERAY_ID=$(docker ps -a -q --filter="publish=18080")
	gw forceDeploy -Ddeploy.docker.container.id=$LIFERAY_ID

elif [ $OPTION == "deploy"  ]; then
	echo "spinner $OPTION"
	LIFERAY_ID=$(docker ps -a -q --filter="publish=18080")
	gw deploy -Ddeploy.docker.container.id=$LIFERAY_ID

elif [ $OPTION == "deployDev"  ]; then
	echo "spinner $OPTION"
	LIFERAY_ID=$(docker ps -a -q --filter="publish=18080")
	gw deployDev -Ddeploy.docker.container.id=$LIFERAY_ID

elif [ $OPTION == "database"  ]; then
	echo "spinner $OPTION"
	DATABASE_PASSWORD="password"
	cd ~/dev/projects/liferay-docker/spinner/env-$ENV_NAME*/	
	docker compose stop search antivirus liferay-1
	docker compose start database

	DATABASE_ID=$(docker ps -a -q --filter="name=database_")
    printf '\n'

	printf 'Starting database clean up'
    sleep .5
    printf '.'
    sleep .5
    printf '.'
    sleep .5
    printf '.'
    sleep .5
    printf '\n'
 
	docker exec -it $DATABASE_ID mysqladmin -p$DATABASE_PASSWORD drop lportal create lportal -f 
 
elif [ $OPTION == "reset"  ]; then
	echo "spinner $OPTION"
	rm -rf ~/dev/projects/liferay-docker
	rm -rf ~/dev/projects/liferay-lxc
	printf 'liferay-docker and liferay-lxc repositories were deleted.'

elif [ $OPTION == "prune"  ]; then
	echo "spinner $OPTION"
	printf '\n'
	read -r -p "WARNING! This will stop and remove all dockers from system. Are you sure? [y/N] "
 	response=${response,,} 
	printf '\n'
 	if [[ $response =~ ^(y| ) ]] || [[ -z $response ]]; then
    	docker stop $(docker ps -a -q) 
		docker rm $(docker ps -a -q)
		printf '\n'
		docker system prune --all --volumes
 	fi
else
	echo -e "Choose an option:  \n- spinner build \n- spinner start \n- spinner stop  \n- spinner restart \n- spinner rm \n- spinner deploy \n- spinner deployDev \n- spinner database \n- spinner reset \n- spinner prune \n- spinner deployMP"
fi