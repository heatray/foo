node('master') {
	checkout scm
	utils = load "utils.groovy"	
}

defaults = [
	linux:           false,
	android:         false,
	editors:         false,
	builder:         false,
	server_ce:       false,
	server_ee:       false,
	server_de:       false,
	libs:            false,
	cron:            'H 17 * * *'
]

if (BRANCH_NAME == 'master') {
	defaults.putAll([
		linux:         true,
		editors:       true
	])
}

pipeline {
	agent none
	environment {
		COMPANY_NAME = 'ONLYOFFICE'
		RELEASE_BRANCH = 'stable'
		PRODUCT_VERSION = '1.0.0'
	}
	parameters {
		booleanParam (
			defaultValue: false,
			description:  'Wipe out current workspace',
			name:         'wipe'
		)
		booleanParam (
			defaultValue: defaults.linux,
			description:  'Build Linux x64 targets',
			name:         'linux_64'
		)
		booleanParam (
			defaultValue: defaults.android,
			description:  'Build Android targets',
			name:         'android'
		)
		booleanParam (
			defaultValue: defaults.editors,
			description:  'Build and publish DesktopEditors packages',
			name:         'editors'
		)
		booleanParam (
			defaultValue: defaults.builder,
			description:  'Build and publish DocumentBuilder packages',
			name:         'builder'
		)
		booleanParam (
			defaultValue: defaults.server_ce,
			description:  'Build and publish DocumentServer packages',
			name:         'server_ce'
		)
		booleanParam (
			defaultValue: defaults.server_ee,
			description:  'Build and publish DocumentServer-EE packages',
			name:         'server_ee'
		)
		booleanParam (
			defaultValue: defaults.server_de,
			description:  'Build and publish DocumentServer-DE packages',
			name:         'server_de'
		)
		booleanParam (
			defaultValue: defaults.libs,
			description:  'Build and publish Android libs packages',
			name:         'libs'
		)
	}
	stages {
		stage('Prepare') {
			steps {
				script {
					def branchName = env.BRANCH_NAME
					def productVersion = "99.99.99"
					def pV = branchName =~ /^(release|hotfix)\\/v(.*)$/
					if (pV.find()) productVersion = pV.group(2)

					env.PRODUCT_VERSION = productVersion
					if (params.signing) env.ENABLE_SIGNING=1

					deployMap = []
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
							if (params.wipe) {
								deleteDir()
								checkout scm
							}

							String platform = "linux"

							if (params.editors)   buildEditors(platform)
							// if (params.builder)   buildBuilder(platform)
							// if (params.server_ce) buildServer(platform)
							// if (params.server_ee) buildServer(platform, "enterprise")
							// if (params.server_de) buildServer(platform, "developer")
							// if (params.android)   buildAndroid(platform)
						}
					}
				}
			}
		}
	}
	post {
		success {
			node('master') {
				script {
					createReports()
				}
			}
		}
	}
}

// Build Packages

def buildEditors (String platform) {
	String version = env.PRODUCT_VERSION + "-" + env.BUILD_NUMBER
	Map files = [:]

	if (platform == "linux") {

		sh """
			mkdir -pv desktop-apps/win-linux/package/linux
			cd desktop-apps/win-linux/package/linux
			mkdir -pv deb rpm apt-rpm urpmi tar

			fallocate -l 10M deb/onlyoffice-desktopeditors_6.4.0-58_amd64.deb
			fallocate -l 11M rpm/onlyoffice-desktopeditors-6.4.0-58.x86_64.rpm
			fallocate -l 12M apt-rpm/onlyoffice-desktopeditors-6.4.0-58.x86_64.rpm
			fallocate -l 13M urpmi/onlyoffice-desktopeditors-6.4.0-58.x86_64.rpm
			fallocate -l 14M tar/onlyoffice-desktopeditors-6.4.0-58-x64.tar.gz
		"""

		dir ("desktop-apps/win-linux/package/linux") {
			files."Ubuntu"     = uploadFiles("deb/*.deb",        "ubuntu/")
			files."CentOS"     = uploadFiles("rpm/**/*.rpm",     "centos/")
			files."AltLinux"   = uploadFiles("apt-rpm/**/*.rpm", "altlinux/")
			files."Rosa"       = uploadFiles("urpmi/**/*.rpm",   "rosa/")
			files."Portable"   = uploadFiles("tar/*.tar.gz",     "linux/")
			// files."AstraLinux" = uploadFiles("deb-astra/*.deb", "astralinux/")
		}

	}

	files.each {
		it.value.each { file ->
			deployMap.add([
				product: "editors",
				platform: platform,
				section: it.key,
				path: file.path,
				file: file.file,
				size: file.size,
				md5: file.md5
			])
		}
	}

	Map filesW = [:]
	sh """
		mkdir -pv desktop-apps/win-linux/package/windows/update
		cd desktop-apps/win-linux/package/windows

		fallocate -l 15M ONLYOFFICE_DesktopEditors_6.4.0.59_x64.exe
		fallocate -l 16M ONLYOFFICE_DesktopEditors_6.4.0.59_x64.zip
		fallocate -l 9M update/editors_update_6.4.0.59_x64.exe
		fallocate -l 8M update/appcast.xml
		fallocate -l 7M update/changes.html
		fallocate -l 6M update/changes_ru.html
	"""

	dir ("desktop-apps/win-linux/package/windows") {
		filesW."Installer"  = uploadFiles("*.exe", "windows/")
		filesW."Portable"   = uploadFiles("*.zip", "windows/")
		filesW."WinSparkle" = uploadFiles(
			"update/*.exe,update/*.xml,update/*.html", "windows/editors/${version}/")
	}

	filesW.each {
		it.value.each { file ->
			deployMap.add([
				product: "editors",
				platform: "windows",
				section: it.key,
				path: file.path,
				file: file.file,
				size: file.size,
				md5: file.md5
			])
		}
	}
}

// Deploy

def uploadFiles(String glob, String dest) {
	Boolean isUnix = isUnix()
	String s3uri, md5sum
	ArrayList ret = []

	def cmdUpload = { local, remote ->
		return "echo cp ${local} s3://${remote}"
	}
	def cmdMd5sum = {
		return "md5sum ${it} | cut -f 1 -d ' '"
	}

	findFiles(glob: glob).each {
		s3uri = "repo-doc-onlyoffice-com/${env.COMPANY_NAME.toLowerCase()}" \
			+ "/${env.RELEASE_BRANCH}/${dest}${dest.endsWith('/') ? it.name : ''}"
		// cmdUpload = "echo cp ${it.path} s3://${s3uri}"

		if (isUnix) sh  cmdUpload(it.path, s3uri)
		else        bat cmdUpload(it.path, s3uri)

		// cmdMd5sum = "md5sum ${it.path} | cut -f 1 -d ' '"

		if (isUnix) md5sum = sh (script: cmdMd5sum(it.path), returnStdout: true).trim()
		else        md5sum = bat (script: cmdMd5sum(it.path), returnStdout: true).trim()

		ret.add([
			path: s3uri,
			file: it.name,
			size: it.length,
			md5: md5sum
		])
	}

	return ret
}

def createReports() {
	Map deploy = deployMap.groupBy { it.product }

	Boolean editors = deploy.editors != null
	Boolean builder = deploy.builder != null
	Boolean server_ce = deploy.server_ce != null
	Boolean server_ee = deploy.server_ee != null
	Boolean server_de = deploy.server_de != null
	Boolean android = deploy.android != null

	dir ("html") {
		sh """
			rm -fv *.html
			test -f style.css || wget -nv https://unpkg.com/style.css -O style.css
		"""

		if (editors)
			writeReports("DesktopEditors", ["editors.html": deploy.editors])
		if (builder)
			writeReports("DocumentBuilder", ["builder.html": deploy.builder])
		if (server_ce || server_ee || server_de) {
			Map serverReports
			if (server_ce) serverReports."server_ce.html" = deploy.server_ce
			if (server_ee) serverReports."server_ee.html" = deploy.server_ee
			if (server_de) serverReports."server_de.html" = deploy.server_de
			writeReports("DocumentServer", serverReports)
		}
		if (android)
			writeReports("Android", ["android.html": deploy.android])
	}
}

def writeReports(String title, Map files) {
	files.each {
		writeFile file: it.key, text: getHtml(it.value)
	}
	publishHTML([
		allowMissing: false,
		alwaysLinkToLastBuild: false,
		includes: files.collect({ it.key }).join(',') + ",*.css",
		keepAll: true,
		reportDir: '',
		reportFiles: files.collect({ it.key }).join(','),
		reportName: title,
		reportTitles: ''
	])
}

def getHtml(ArrayList data) {
	String text, url, size

	text = "<html>\n<head>" \
		+ "\n  <link rel=\"stylesheet\" href=\"style.css\">" \
		+ "\n  <style type=\"text/css\">" \
		+ "\n    body {" \
		+ "\n      margin: 24px;" \
		+ "\n    }" \
		+ "\n    .flex {" \
		+ "\n      display: flex;" \
		+ "\n      justify-content: space-between;" \
		+ "\n    }" \
		+ "\n  </style>" \
		+ "\n<head>\n<body>"
	data.groupBy { it.platform }.each { platform, sections ->
		text += "\n  <h3>${platform}</h3>"
		text += "\n  <ul>"
		sections.groupBy { it.section }.each { section, files ->
			text += "\n    <li><b>${section}</b></li>"
			text += "\n    <ul>"
			files.each {
				url = "https://s3.eu-west-1.amazonaws.com/${it.path}"
				size = sh (script: "LANG=C numfmt --to=iec-i ${it.size}",
					returnStdout: true).trim()
				text += "\n      <li class=\"flex\">"
				text += "\n        <span><a href=\"${url}\">${it.file}</a></span>"
				text += "\n        <span>size: ${size}B</span>"
				text += "\n        <span>md5: <code>${it.md5}</code></span>"
				text += "\n      </li>"
			}
			text += "\n    </ul>"
		}
		text += "\n  </ul>"
	}
	text += "\n</body>\n</html>"

	return text
}
