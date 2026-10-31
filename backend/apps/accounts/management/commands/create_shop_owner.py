from django.core.management.base import BaseCommand, CommandError
from django.contrib.auth.password_validation import validate_password
from django.db import transaction
from django.db.models import Q

from apps.accounts.models import User
from apps.shops.models import Shop


class Command(BaseCommand):
    help = "Create an owner account and its shop; prompts securely for the password."

    def add_arguments(self, parser):
        parser.add_argument("--username", required=True)
        parser.add_argument("--email", required=True)
        parser.add_argument("--phone", required=True)
        parser.add_argument("--shop-name", required=True)
        parser.add_argument("--address", required=True)
        parser.add_argument("--first-name", required=True)
        parser.add_argument("--last-name", default="")

    @transaction.atomic
    def handle(self, *args, **options):
        if User.objects.filter(
            Q(email__iexact=options["email"]) | Q(phone=options["phone"])
        ).exists():
            raise CommandError("An account with that email or phone already exists.")
        password = self.get_password()
        validate_password(password)
        user = User.objects.create_user(
            username=options["username"],
            email=options["email"],
            phone=options["phone"],
            first_name=options["first_name"],
            last_name=options["last_name"],
            password=password,
            role=User.Role.OWNER,
        )
        Shop.objects.create(
            owner=user,
            shop_name=options["shop_name"],
            address=options["address"],
            phone=options["phone"],
        )
        self.stdout.write(self.style.SUCCESS(f"Created shop owner {user.username}."))

    @staticmethod
    def get_password():
        from getpass import getpass

        password = getpass("Password: ")
        if not password or password != getpass("Password (again): "):
            raise CommandError("Passwords must be non-empty and match.")
        return password
