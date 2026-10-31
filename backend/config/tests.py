from django.core.exceptions import ImproperlyConfigured
from django.test import SimpleTestCase

from config.production import validate_production_environment


class ProductionConfigurationTests(SimpleTestCase):
    def setUp(self):
        self.production_environment = {
            "DJANGO_SECRET_KEY": "s" * 50,
            "OTP_HASH_KEY": "h" * 50,
            "DJANGO_ALLOWED_HOSTS": "api.freshkart.example",
            "DJANGO_SECURE_SSL_REDIRECT": "true",
            "DB_NAME": "freshkart",
            "DB_USER": "freshkart",
            "DB_PASSWORD": "private",
            "STORAGE_BACKEND": "s3",
            "AWS_STORAGE_BUCKET_NAME": "freshkart-media",
            "AWS_ACCESS_KEY_ID": "access-key",
            "AWS_SECRET_ACCESS_KEY": "secret-key",
            "SMS_OTP_PROVIDER": "msg91",
            "MSG91_AUTH_KEY": "test-provider-key",
            "MSG91_OTP_TEMPLATE_ID": "test-template-id",
        }

    def test_complete_production_environment_is_accepted(self):
        validate_production_environment(self.production_environment)

    def test_missing_database_fails_instead_of_using_sqlite(self):
        environment = self.production_environment.copy()
        environment.pop("DB_NAME")

        with self.assertRaisesMessage(ImproperlyConfigured, "PostgreSQL"):
            validate_production_environment(environment)

    def test_missing_cloud_storage_is_rejected(self):
        environment = self.production_environment.copy()
        environment["STORAGE_BACKEND"] = "filesystem"

        with self.assertRaisesMessage(ImproperlyConfigured, "STORAGE_BACKEND"):
            validate_production_environment(environment)

    def test_weak_secret_local_hosts_and_disabled_https_are_rejected(self):
        environment = {
            **self.production_environment,
            "DJANGO_SECRET_KEY": "short",
            "OTP_HASH_KEY": "short",
            "DJANGO_ALLOWED_HOSTS": "localhost,127.0.0.1",
            "DJANGO_SECURE_SSL_REDIRECT": "false",
        }

        with self.assertRaises(ImproperlyConfigured) as error:
            validate_production_environment(environment)

        self.assertIn("DJANGO_SECRET_KEY", str(error.exception))
        self.assertIn("OTP_HASH_KEY", str(error.exception))
        self.assertIn("DJANGO_ALLOWED_HOSTS", str(error.exception))
        self.assertIn("DJANGO_SECURE_SSL_REDIRECT", str(error.exception))

    def test_debug_mode_keeps_local_development_configuration(self):
        validate_production_environment({"DJANGO_DEBUG": "true"})
