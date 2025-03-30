def call(String buildStatus = 'STARTED', String deploymentName = 'Unknown') {
  buildStatus = buildStatus ?: 'SUCCESS'

  def color
  def emoji

  if (buildStatus == 'SUCCESS') {
    color = '#47ec05'
    emoji = ':ww:'
  } else if (buildStatus == 'UNSTABLE') {
    color = '#d5ee0d'
    emoji = ':deadpool:'
  } else {
    color = '#ec2805'
    emoji = ':hulk:'
  }

  env.failedStage = env.failedStage ?: 'N/A'
  env.emoji = env.emoji ?: emoji
  env.BUILD_URL = env.BUILD_URL ?: '#'
  env.GIT_COMMIT = env.GIT_COMMIT ?: 'N/A'
  env.GIT_PREVIOUS_SUCCESSFUL_COMMIT = env.GIT_PREVIOUS_SUCCESSFUL_COMMIT ?: 'N/A'
  env.GIT_BRANCH = env.GIT_BRANCH ?: 'N/A'
  env.GIT_URL = env.GIT_URL ?: '#'
  def applicationURL = env.applicationURL ?: '#'

  def attachments = [
    [
      color: color,
      blocks: [
        [
          type: "header",
          text: [
            type: "plain_text",
            text: "K8S Deployment - ${deploymentName} Pipeline ${env.emoji}",
            emoji: true
          ]
        ],
        [
          type: "section",
          fields: [
            [
              type: "mrkdwn",
              text: "*Job Name:*\n${env.JOB_NAME}"
            ],
            [
              type: "mrkdwn",
              text: "*Build Number:*\n${env.BUILD_NUMBER}"
            ]
          ],
          accessory: [
            type: "image",
            image_url: "https://raw.githubusercontent.com/sidd-harth/devsecops-k8s-demo/main/slack-emojis/jenkins.png",
            alt_text: "Slack Icon"
          ]
        ],
        [
          type: "section",
          text: [
            type: "mrkdwn",
            text: "*Failed Stage Name:* `${env.failedStage}`"
          ],
          accessory: [
            type: "button",
            text: [
              type: "plain_text",
              text: "Jenkins Build URL",
              emoji: true
            ],
            url: "${env.BUILD_URL}",
            action_id: "button-action"
          ]
        ],
        [
          type: "divider"
        ],
        [
          type: "section",
          fields: [
            [
              type: "mrkdwn",
              text: "*Kubernetes Deployment Name:*\n${deploymentName}"
            ],
            [
              type: "mrkdwn",
              text: "*Node Port:*\n32564"
            ]
          ],
          accessory: [
            type: "image",
            image_url: "https://raw.githubusercontent.com/sidd-harth/devsecops-k8s-demo/main/slack-emojis/k8s.png",
            alt_text: "Kubernetes Icon"
          ]
        ],
        [
          type: "section",
          text: [
            type: "mrkdwn",
            text: "*Kubernetes Node:* `controlplane`"
          ],
          accessory: [
            type: "button",
            text: [
              type: "plain_text",
              text: "Application URL",
              emoji: true
            ],
            url: "${applicationURL}:32564",
            action_id: "button-action"
          ]
        ],
        [
          type: "divider"
        ],
        [
          type: "section",
          fields: [
            [
              type: "mrkdwn",
              text: "*Git Commit:*\n${env.GIT_COMMIT}"
            ],
            [
              type: "mrkdwn",
              text: "*GIT Previous Success Commit:*\n${env.GIT_PREVIOUS_SUCCESSFUL_COMMIT}"
            ]
          ],
          accessory: [
            type: "image",
            image_url: "https://raw.githubusercontent.com/sidd-harth/devsecops-k8s-demo/main/slack-emojis/github.png",
            alt_text: "Github Icon"
          ]
        ],
        [
          type: "section",
          text: [
            type: "mrkdwn",
            text: "*Git Branch:* `${env.GIT_BRANCH}`"
          ],
          accessory: [
            type: "button",
            text: [
              type: "plain_text",
              text: "Github Repo URL",
              emoji: true
            ],
            url: "${env.GIT_URL}",
            action_id: "button-action"
          ]
        ]
      ]
    ]
  ]

  slackSend(iconEmoji: emoji, attachments: attachments)
}
