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
	cron:            'H 17 * * *',
	version:         '1.0.0',
	release_branch:  'experimental'
]

if (BRANCH_NAME == 'master') {
	defaults.putAll([
		linux:           true,
		editors:         true,
		release_branch:  'stable'
	])
}

if (BRANCH_NAME == 'develop') {
	defaults.putAll([
		branch:        'unstable'
	])
}

if (BRANCH_NAME ==~ /^(hotfix|release)\/.+/) {
	defaults.putAll([
		branch:        'testing',
		version:       BRANCH_NAME.replaceAll(/.+\/v(?=[0-9.]+)/,''),
	])
}

pipeline {
	agent none
	environment {
		COMPANY_NAME = "ONLYOFFICE"
		RELEASE_BRANCH = "${defaults.release_branch}"
		PRODUCT_VERSION = "${defaults.version}"
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

							String platform = "linux_64"

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
					generateReports()
				}
			}
		}
	}
}

// Build Packages

void buildEditors (String platform) {
	String version = env.PRODUCT_VERSION + "-" + env.BUILD_NUMBER
	String product = "editors"

	if (platform == "linux_64") {
		String section = "Linux x64"

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
			uploadFiles("deb/*.deb",        "ubuntu/",   product, section, "Ubuntu")
			uploadFiles("rpm/**/*.rpm",     "centos/",   product, section, "CentOS")
			uploadFiles("apt-rpm/**/*.rpm", "altlinux/", product, section, "AltLinux")
			uploadFiles("urpmi/**/*.rpm",   "rosa/",     product, section, "Rosa")
			uploadFiles("tar/*.tar.gz",     "linux/",    product, section, "Portable")
			// uploadFiles("deb-astra/*.deb",  "astralinux/", product, section, "AstraLinux")
		}

	}

	String section = "Windows x64"

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
		uploadFiles("*.exe", "windows/", product, section, "Installer")
		uploadFiles("*.zip", "windows/", product, section, "Portable")
		uploadFiles("update/*.exe,update/*.xml,update/*.html",
			"windows/editors/${version}/", product, section, "WinSparkle")
	}
}

// Deploy

void uploadFiles(String glob, String dest, String product, String platform, String section) {
	String s3uri, md5sum, shasum

	Closure cmdUpload = { local, remote ->
		String cmd = "echo cp ${local} s3://${remote}"
		sh cmd
		return this
		if (platform ==~ /^Windows.*/) {
			bat cmd
		} else {
			sh cmd
		}
	}

	Closure cmdMd5sum = {
		return sh (script: "md5sum ${it} | cut -c -32", returnStdout: true).trim()
		if (platform ==~ /^Windows.*/) {
			return bat (script: "md5sum ${it} | cut -c -32", returnStdout: true).trim()
		} else if (platform ==~ /^macOS.*/) {
			return sh (script: "md5 -qs ${it}", returnStdout: true).trim()
		} else {
			return sh (script: "md5sum ${it} | cut -c -32", returnStdout: true).trim()
		}
	}

	// Closure cmdSha256sum = {
	// 	return sh (script: "shasum -a 256 ${it} | cut -c -64", returnStdout: true).trim()
	// 	if (platform ==~ /^Windows.+/) {
	// 		return bat (script: "md5sum ${it} | cut -c -32", returnStdout: true).trim()
	// 	} else if (platform ==~ /^macOS.+/) {
	// 		return sh (script: "shasum -a 256 ${it} | cut -c -64", returnStdout: true).trim()
	// 	} else {
	// 		return sh (script: "md5sum ${it} | cut -c -32", returnStdout: true).trim()
	// 	}
	// }

	findFiles(glob: glob).each {
		s3uri = "repo-doc-onlyoffice-com/${env.COMPANY_NAME.toLowerCase()}" \
			+ "/${env.RELEASE_BRANCH}/${dest}${dest.endsWith('/') ? it.name : ''}"

		cmdUpload(it.path, s3uri)

		deployMap.add([
			product: product,
			platform: platform,
			section: section,
			path: s3uri,
			file: it.name,
			size: it.length,
			md5: cmdMd5sum(it.path)
			// sha256: cmdSha256sum(it.path)
		])
	}
}

void generateReports() {
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
			Map serverReports = [:]
			if (server_ce) serverReports."server_ce.html" = deploy.server_ce
			if (server_ee) serverReports."server_ee.html" = deploy.server_ee
			if (server_de) serverReports."server_de.html" = deploy.server_de
			writeReports("DocumentServer", serverReports)
		}
		if (android)
			writeReports("Android", ["android.html": deploy.android])
	}
}

void writeReports(String title, Map files) {
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
	String text, url
	Closure size = {
		return sh (script: "LANG=C numfmt --to=iec-i ${it}", returnStdout: true).trim()
	}

	text = "<html>\n<head>" \
		+ "\n  <link rel=\"stylesheet\" href=\"style.css\">" \
		+ "\n  <style type=\"text/css\">" \
		+ "\n    body { margin: 24px; }" \
		+ "\n  </style>" \
		+ "\n<head>\n<body>"
	data.groupBy { it.platform }.each { platform, sections ->
		text += "\n  <h3>${platform}</h3>\n  <ul>"
		sections.groupBy { it.section }.each { section, files ->
			text += "\n    <li><b>${section}</b></li>\n    <ul>"
			files.each {
				url = "https://s3.eu-west-1.amazonaws.com/${it.path}"
				text += "\n      <li>" \
					+ "\n        <a href=\"${url}\">${it.file}</a>" \
					+ ", Size: ${size(it.size)}B" \
					+ ", MD5: <code>${it.md5}</code>" \
					+ "\n      </li>"
					// + ", SHA-256: <code>${it.sha256}</code>" \
			}
			text += "\n    </ul>"
		}
		text += "\n  </ul>"
	}
	text += "\n</body>\n</html>"

	return text
}
