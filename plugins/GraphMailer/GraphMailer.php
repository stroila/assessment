<?php

use LimeSurvey\PluginManager\EmailPluginBase;
use LimeSurvey\PluginManager\GraphPHPMailer;
//use PHPMailer\PHPMailer\PHPMailer;

class GraphMailer extends EmailPluginBase
{
    protected $storage = 'DbStorage';
    static protected $name = 'GraphMailer';
    static protected $description = 'Microsoft Graph SMTP replacement';

    protected $settings = [
        'clientId' => [
            'type' => 'string',
            'label' => 'Client ID',
        ],
        'clientSecret' => [
            'type' => 'string',
            'label' => 'Client Secret',
        ],
        'tenantId' => [
            'type' => 'string',
            'label' => 'Tenant ID',
        ],
    ];

    public function init()
    {
        $this->subscribe('listEmailPlugins');
        $this->subscribe('beforePrepareRedirectToAuthPage');
        $this->subscribe('beforeSendEmail');
    }

    /**
     * @inheritdoc
     * Update the information content
     */
    public function getPluginSettings($getValues = true)
    {
        $settings = parent::getPluginSettings($getValues);
        $settings['clientId']['label'] = gT("Client ID");
        $settings['clientSecret']['label'] = gT("Client Secret");
        $settings['tenantId']['label'] = gT("Tenant ID");

        return $settings;
    }

    public function listEmailPlugins()
    {
        $event = $this->getEvent();
        $event->append('plugins', [
            'graph' => $this->getEmailPluginInfo()
        ]);
    }

    /**
     * @inheritdoc
     */
    protected function getDisplayName()
    {
        return 'Graph';
    }

    /**
     * Handles the beforePrepareRedirectToAuthPage event, triggered before the
     * page with the "Get Token" button is rendered.
     */
    public function beforePrepareRedirectToAuthPage()
    {
        $event = $this->getEvent();
        $event->set('width', 600);
        $event->set('height', 800);
        $event->set('providerName', $this->getDisplayName());

        $setupStatus = $this->getSetupStatus();
        $description = $this->getSetupStatusDescription($setupStatus);
        $event->setContent($this, $description);
    }


    public function beforeSendEmail()
    {

        $event = $this->getEvent();
        $this->Mailer = 'graph';

/*
        try {
            $success = $this->sendViaGraph($event);

            if ($success) {
                $event->set('success', true);
                $event->stop(); // prevent SMTP
            }

        } catch (Exception $e) {
            Yii::log(
                'GraphMailer error: ' . $e->getMessage(),
                CLogger::LEVEL_ERROR,
                'GraphMailer'
            );

            if (!$this->get('fallbackSMTP')) {
                $event->set('success', false);
                $event->stop();
            }
        }
 */
    }

    private function mapRecipients(array $addresses): array
    {
        return array_values(array_filter(array_map(function ($email) {
            if (!$email) return null;
            return [
                'emailAddress' => ['address' => $email]
            ];
        }, $addresses)));
    }

    private function getAccessToken(): ?string
    {
        $url = "https://login.microsoftonline.com/"
             . $this->get('tenantId')
             . "/oauth2/v2.0/token";

        $post = http_build_query([
            'client_id'     => $this->get('clientId'),
            'client_secret' => $this->get('clientSecret'),
            'scope'         => 'https://graph.microsoft.com/.default',
            'grant_type'    => 'client_credentials'
        ]);

        $ch = curl_init($url);
        curl_setopt_array($ch, [
            CURLOPT_POST => true,
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_POSTFIELDS => $post,
            CURLOPT_HTTPHEADER => [
                'Content-Type: application/x-www-form-urlencoded',
            ],
        ]);

        $response = json_decode(curl_exec($ch), true);
        curl_close($ch);

        return $response['access_token'] ?? null;
    }
}
