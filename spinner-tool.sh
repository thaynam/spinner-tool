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
	ENV_NAME=${ENV_NAME:-e5a2prd}
	RELEASE_VERSION=${RELEASE_VERSION:-next}
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
		mkdir dev/projects
	fi

	if [ ! -d "$LIFERAY_DOCKER_DIR" ] ; then
		git clone $LIFERAY_DOCKER_REMOTE $LIFERAY_DOCKER_DIR
		cd $LIFERAY_DOCKER_DIR
		git checkout master
		git pull 
		git reset HEAD --hard

	else
		cd $LIFERAY_DOCKER_DIR
		git checkout master
		git pull 
		git reset HEAD --hard
	fi

	## create or  update liferay-lxc
	LIFERAY_LXC_DIR=~/dev/projects/liferay-lxc
	LIFERAY_LXC_REMOTE=git@github.com:liferay/liferay-lxc.git

	if [ ! -d "$LIFERAY_LXC_DIR" ] ; then
		git clone $LIFERAY_LXC_REMOTE $LIFERAY_LXC_DIR
		cd $LIFERAY_LXC_DIR
		git checkout 7.4-$RELEASE_VERSION
		git pull 
		git reset HEAD --hard

	else
		cd $LIFERAY_LXC_DIR
		git checkout 7.4-$RELEASE_VERSION
		git pull 
		git reset HEAD --hard
	fi
	
	## stop and remove all mysql dockers
	# docker rm $(docker stop $(docker ps -a -q --filter="expose=3306"))
	## stop and remov	e all dockers with env name
	docker rm $(docker stop $(docker ps -a -q --filter="name=env-$ENV_NAME*"))
	## copy dxp-activation-key to spinner directory
	rsync -avz $DXP_ACTIVATION_KEY_DIR ~/dev/projects/liferay-docker/spinner/dxp-activation-key 
	##	remove old cluster dir
	cd ~/dev/projects/liferay-docker/spinner
	rm -rf ~/dev/projects/liferay-docker/spinner/env-$ENV_NAME*/
	## build spinner 
	./build.sh $ENV_NAME
	cd ~/dev/projects/liferay-docker/spinner/env-$ENV_NAME*/
	## create spinner dockers
	docker-compose up -d antivirus database search && docker-compose up liferay-1	

elif [ $OPTION == "start" ]; then
	echo "spinner $OPTION"
	docker start $(docker ps -a -q --filter="name=env-$ENV_NAME*")
	LIFERAY_ID=$(docker ps -a -q --filter="publish=18080")
	docker logs -f $LIFERAY_ID

elif [ $OPTION == "stop"  ]; then
	echo "spinner $OPTION"
	docker stop $(docker ps -a -q --filter="name=env-$ENV_NAME*")

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

elif [ $OPTION == "deployStaging"  ]; then
	echo "spinner $OPTION"
	LIFERAY_ID=$(docker ps -a -q --filter="publish=18080")
	gw deployStaging -Ddeploy.docker.container.id=$LIFERAY_ID
else
	echo -e "Choose an option:  \n- spinner build \n- spinner start \n- spinner stop \n- spinner rm \n- spinner forceDeploy \n- spinner deploy "
fi