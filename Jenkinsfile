// node('master') {
// 	checkout scm
// 	utils = load "utils.groovy"	
// }

defaults = [
	linux:           false,
	android:         false,
	editors:         false,
	builder:         false,
	server_ce:       false,
	server_ee:       false,
	server_de:       false,
	cron:            'H 17 * * *'
]

if ('master' == BRANCH_NAME) {
	defaults.putAll([
		linux:         true,
		editors:       true
	])
}

println BRANCH_NAME.startsWith('hotfix')
println BRANCH_NAME.startsWith('release')


pipeline {
	agent { label 'master' }
	parameters {
		booleanParam (
			defaultValue: false,
			description: 'Wipe out current workspace',
			name: 'wipe'
		)
		booleanParam (
			defaultValue: defaults.linux,
			description: 'Build Linux x64 targets',
			name: 'linux_64'
		)
		booleanParam (
			defaultValue: defaults.android,
			description: 'Build Android targets',
			name: 'android'
		)
		booleanParam (
			defaultValue: defaults.editors,
			description: 'Build and publish DesktopEditors packages',
			name: 'desktopeditor'
		)
		booleanParam (
			defaultValue: defaults.builder,
			description: 'Build and publish DocumentBuilder packages',
			name: 'documentbuilder'
		)
		booleanParam (
			defaultValue: defaults.server_ce,
			description: 'Build and publish DocumentServer packages',
			name: 'documentserver'
		)
		booleanParam (
			defaultValue: defaults.server_ee,
			description: 'Build and publish DocumentServer-EE packages',
			name: 'documentserver_ee'
		)
		booleanParam (
			defaultValue: defaults.server_de,
			description: 'Build and publish DocumentServer-DE packages',
			name: 'documentserver_de'
		)
	}
	triggers {
		cron(defaults.cron)
	}
	stages {
		stage('Prepare') {
			steps {
				script {
					// checkout scm
					utils = load "utils.groovy"

					println utils.listRepos

					checkout([
						$class: 'GitSCM',
						branches: [[name: 'master']],
						extensions: [
							[$class: 'CloneOption', depth: 1, shallow: true],
							[$class: 'SubmoduleOption', depth: 1, recursiveSubmodules: true, shallow: true],
							[$class: 'RelativeTargetDirectory', relativeTargetDir: 'test'],
							[$class: 'ScmName', name: 'heatray/KFGimli']
						],
						userRemoteConfigs: [
							[url: 'git@github.com:heatray/KFGimli.git']
						]
					])

					def branchName = env.BRANCH_NAME
					def productVersion = "99.99.99"
					def pV = branchName =~ /^(release|hotfix)\\/v(.*)$/
					if(pV.find()) {
						productVersion = pV.group(2)
					}
					env.PRODUCT_VERSION = productVersion
					env.RELEASE_BRANCH = 'testing'

					if( params.signing ) {
						env.ENABLE_SIGNING=1
					}

					deployDesktopList = []
					deployBuilderList = []
					deployServerCeList = []
					deployServerEeList = []
					deployServerIeList = []
					deployServerDeList = []
					deployAndroidList = []

					currentBuild.properties.each { println "$it.key -> $it.value" }
				}
			}
		}
		stage('Build') {
			parallel {
				stage('Linux 64-bit build') {
					agent { label 'linux_64' }
					when {
						expression { params.linux_64 }
						beforeAgent true
					}
					steps {
						script {
							if ( params.wipe ) {
								deleteDir()
								checkout scm
							}

							if (params.documentbuilder) {
								linuxBuildBuilder()
							}
							if (params.desktopeditor) {
								linuxBuildDesktop()
							}
							if (params.documentserver) {
								linuxBuildServer()
							}
							if (params.documentserver_ee) {
								linuxBuildServer("documentserver-ee")
							}
							if (params.documentserver_ie) {
								linuxBuildServer("documentserver-ie")
							}
							if (params.documentserver_de) {
								linuxBuildServer("documentserver-de")
							}
							if (params.android) {
								androidBuild()
							}
						}
					}
				}
			}
		}
	}
	// post {
	// 	always {
	// 		node('master') {
	// 			script {
	// 				checkout scm
	// 				createReports()
	// 			}
	// 		}
	// 		script {
	// 			if (params.linux_64 && (
	// 				params.desktopeditor ||
	// 				params.documentbuilder ||
	// 				params.documentserver_ee ||
	// 				params.documentserver_ie ||
	// 				params.documentserver_de)
	// 			) {
	// 				build (
	// 					job: 'tokenitem',
	// 					parameters: [
	// 						string (name: 'stringy', value: env.RELEASE_BRANCH)
	// 					],
	// 					wait: false
	// 				)
	// 			}
	// 		}
	// 	}
	// }
}

def linuxBuildDesktop()
{
	sh """#!/bin/bash -xe
		echo desktop
		cat <<- EOF > linuxdesktopdeploy.json
			{
				"product": "desktopeditors",
				"title": "ONLYOFFICE Desktop Editors"
				"version": "6.1.0",
				"build": "90",
				"items": [
					{
						"platform": "ubuntu",
						"title": "Debian 8 9, Ubuntu 14.04 16.04 18.04 and derivatives",
						"path": "onlyoffice/ubuntu/package.deb",
						"size": "250 MB"
					},
					{
						"platform": "centos",
						"title": "Centos 7, Redhat 7, Fedora latest and derivatives",
						"path": "onlyoffice/centos/package.rpm",
						"size": "250 MB"
					},
					{
						"platform": "linux",
						"title": "Linux portable",
						"path": "onlyoffice/linux/package.tar.gz",
						"size": "250 MB"
					}
				],
				"appcast": "<path>",
				"changes": [
					"en": "<path>"
					"ru": "<path>"
				]
			}
		EOF
	"""

	// def deployData = readJSON file: 'linuxdesktopdeploy.json'

	// for(item in deployData.items) {
	// 	println item
	// 	deployDesktopList.add(item)
	// }

	return this
}

def linuxBuildBuilder()
{
	sh """#!/bin/bash -xe
		echo builder
		cat <<- EOF > linuxbuilderdeploy.json
			{
				"product": "documentbuilder",
				"version": "6.1.0",
				"build": "90",
				"items": [
					{
						"platform": "ubuntu",
						"title": "Debian 8 9, Ubuntu 14.04 16.04 18.04 and derivatives",
						"path": "a/package.deb"
					},
					{
						"platform": "centos",
						"title": "Centos 7, Redhat 7, Fedora latest and derivatives",
						"path": "b/package.rpm"
					},
					{
						"platform": "linux",
						"title": "Linux portable",
						"path": "c/package.tar.gz"
					}
				]
			}
		EOF
	"""

	// def deployData = readJSON file: 'linuxbuilderdeploy.json'

	// for(item in deployData.items) {
	// 	println item
	// 	deployBuilderList.add(item)
	// }

	return this
}

def linuxBuildServer(String productName='documentserver')
{
	sh """#!/bin/bash -xe
		echo ${productName}
		cat <<- EOF > linux${productName}deploy.json
			{
				"product": "${productName}",
				"version": "6.1.0",
				"build": "90",
				"items": [
					{
						"platform": "ubuntu",
						"title": "Debian 8 9, Ubuntu 14.04 16.04 18.04 and derivatives",
						"path": "a"
					},
					{
						"platform": "centos",
						"title": "Centos 7, Redhat 7, Fedora latest and derivatives",
						"path": "b"
					},
					{
						"platform": "linux",
						"title": "Linux portable",
						"path": "c"
					}
				]
			}
		EOF
	"""

	// def deployData = readJSON file: "linux${productName}deploy.json"

	// for(item in deployData.items) {
	// 	println item
	// 	switch(productName) {
	// 		case 'documentserver':
	// 			deployServerCeList.add(item)
	// 			break
	// 		case 'documentserver-ee':
	// 			deployServerEeList.add(item)
	// 			break
	// 		case 'documentserver-ie':
	// 			deployServerIeList.add(item)
	// 			break
	// 		case 'documentserver-de':
	// 			deployServerDeList.add(item)
	// 			break
	// 	}
	// }

	return this
}

def androidBuild()
{
	sh """#!/bin/bash -xe
		echo android
		cat <<- EOF > android.json
			{
				"product": "android",
				"version": "6.1.0",
				"build": "90",
				"items": [
					{
						"platform": "android",
						"title": "Android libs",
						"path": "http://a"
					}
				]
			}
		EOF
	"""

	// String androidLibsFile = "android-libs-${env.PRODUCT_VERSION}-${env.BUILD_NUMBER}.zip"
	// String androidLibsUri = "onlyoffice/${env.RELEASE_BRANCH}/android/${androidLibsFile}"
	// def deployData = [platform: 'android', title: 'Android libs', path: androidLibsUri]

	// println deployData
	// deployAndroidList.add(deployData)

	return this
}

def createReports()
{
	Boolean desktop = !deployDesktopList.isEmpty()
	Boolean builder = !deployBuilderList.isEmpty()
	Boolean serverc = !deployServerCeList.isEmpty()
	Boolean servere = !deployServerEeList.isEmpty() 
	Boolean serverd = !deployServerDeList.isEmpty()
	Boolean android = !deployAndroidList.isEmpty()

	dir ('html') {
		deleteDir()

		sh "wget -nv https://unpkg.com/style.css -O style.css"
		sh "echo \"body { margin: 16px; }\" > custom.css"

		if (desktop) { writeFile file: 'desktopeditors.html', text: genHtml(deployDesktopList) }
		if (builder) { writeFile file: 'documentbuilder.html', text: genHtml(deployBuilderList) }
		if (serverc) { writeFile file: 'documentserver_ce.html', text: genHtml(deployServerCeList) }
		if (servere) { writeFile file: 'documentserver_ee.html', text: genHtml(deployServerEeList) }
		if (serverd) { writeFile file: 'documentserver_de.html', text: genHtml(deployServerDeList) }
		if (android) { writeFile file: 'android.html', text: genHtml(deployAndroidList) }
	}

	if (desktop) {
		publishHTML([
			allowMissing: false,
			alwaysLinkToLastBuild: false,
			includes: 'desktopeditors.html,*.css',
			keepAll: true,
			reportDir: 'html',
			reportFiles: 'desktopeditors.html',
			reportName: "DesktopEditors",
			reportTitles: ''
		])
	}
	
	if (builder) {
		publishHTML([
			allowMissing: false,
			alwaysLinkToLastBuild: false,
			includes: 'documentbuilder.html,*.css',
			keepAll: true,
			reportDir: 'html',
			reportFiles: 'documentbuilder.html',
			reportName: "DocumentBuilder",
			reportTitles: ''
		])
	}

	if (serverc || servere || serverd) {
		// compatibility for htmlpublisher-1.18
		def serverIndexFiles = []
		if (serverc) { serverIndexFiles.add('documentserver_ce.html') }
		if (servere) { serverIndexFiles.add('documentserver_ee.html') }
		if (serverd) { serverIndexFiles.add('documentserver_de.html') }

		publishHTML([
			allowMissing: false,
			alwaysLinkToLastBuild: false,
			includes: 'documentserver_*.html,*.css',
			keepAll: true,
			reportDir: 'html',
			reportFiles: serverIndexFiles.join(','),
			// reportFiles: 'documentserver_*.html',
			reportName: "DocumentServer",
			reportTitles: ''
		])
	}

	if (android) {
		publishHTML([
			allowMissing: false,
			alwaysLinkToLastBuild: false,
			includes: 'android.html,*.css',
			keepAll: true,
			reportDir: 'html',
			reportFiles: 'android.html',
			reportName: "Android",
			reportTitles: ''
		])
	}

	return this
}

def genHtml(ArrayList deployList)
{
	String url = ''
	String filename = ''
	String html = """\
		|<html>
		|<head>
		|	<link rel="stylesheet" href="style.css">
		|	<link rel="stylesheet" href="custom.css">
		|<head>
		|<body>
		|	<h2>${deployList.title} <small>${env.PRODUCT_VERSION}-${env.BUILD_NUMBER}</small></h2>
		|	<dl>
		|""".stripMargin()

	for(p in deployList) {
		url = "https://${env.S3_BUCKET}.s3-eu-west-1.amazonaws.com/${p.path}"
		filename = p.path.substring(p.path.lastIndexOf("/") + 1)
		html += """\
			|		<dt>${p.title}</dt>
			|		<dd><a href="${url}" target="_blank">${filename}</a> (${p.size})</dd>
			|""".stripMargin()
	}

	html += """\
		|	</dl>
		|</body>
		|</html>
		|""".stripMargin()

	return html
}
