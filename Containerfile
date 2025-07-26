FROM archlinux:latest

RUN pacman -Sy --noconfirm btrfs-progs btrbk restic python sudo

RUN useradd -m tester && echo "tester ALL=(ALL) NOPASSWD: ALL" >/etc/sudoers.d/tester

USER tester
WORKDIR /home/tester/app
COPY . /home/tester/app

ENTRYPOINT ["/home/tester/app/scripts/test-installation.sh"]

