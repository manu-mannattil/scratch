.PHONY: all
NAME = emem

all:
	rm -f $(NAME).otp
	cd src; zip -r ../$(NAME).otp *
	mkdir -p ~/.config/libreoffice/4/user/template
	cp -f $(NAME).otp ~/.config/libreoffice/4/user/template

unpack: $(NAME).otp
	rm -rf src
	mkdir src
	cd src; unzip ../$(NAME).otp; find . -name "*.xml" -type f -exec xmllint --output '{}' --format '{}' \;
