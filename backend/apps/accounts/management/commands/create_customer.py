from django.contrib.auth.password_validation import validate_password
from django.core.management.base import BaseCommand, CommandError

from apps.accounts.models import User


class Command(BaseCommand):
    help = "Create a customer account; prompts securely for the password."

    def add_arguments(self, parser):
        parser.add_argument("--username", required=True)
        parser.add_argument("--email", required=True)
        parser.add_argument("--phone", required=True)
        parser.add_argument("--first-name", required=True)
        parser.add_argument("--last-name", default="")

    def handle(self, *args, **options):
        if User.objects.filter(
            email__iexact=options["email"]
        ).exists() or User.objects.filter(phone=options["phone"]).exists():
            raise CommandError("An account with that email or phone already exists.")
        password = self.get_password()
        validate_password(password)
        customer = User.objects.create_user(
            username=options["username"],
            email=options["email"],
            phone=options["phone"],
            first_name=options["first_name"],
            last_name=options["last_name"],
            password=password,
            role=User.Role.CUSTOMER,
        )
        self.stdout.write(self.style.SUCCESS(f"Created customer {customer.username}."))

    @staticmethod
    def get_password():
        from getpass import getpass

        password = getpass("Password: ")
        if not password or password != getpass("Password (again): "):
            raise CommandError("Passwords must be non-empty and match.")
        return password
