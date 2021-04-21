def checkoutRepo(String repo, String branch = 'master', String dir = repo, String company = 'test1155') {
    checkout([
            $class: 'GitSCM',
            branches: [[
                    name: branch
                ]
            ],
            doGenerateSubmoduleConfigurations: false,
            extensions: [[
                    $class: 'RelativeTargetDirectory',
                    relativeTargetDir: dir
                ]
            ],
            submoduleCfg: [],
            userRemoteConfigs: [[
                    url: "git@github.com:${company}/${repo}.git"
                ]
            ]
        ]
    )
}

listRepos = [
  [owner: 'heatray', name: 'foo'],
  [owner: 'heatray', name: 'bar'],
  [owner: 'heatray', name: 'baz']
]

return this
