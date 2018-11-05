FROM alpine

RUN apk --no-cache add wget curl bash html-xml-utils xmlstarlet tidyhtml ca-certificates openssl jq git

#RUN curl -q https://kubernetes.io/docs/imported/release/ |  tidy -q -numeric -asxhtml --show-warnings no \
#	| xmlstarlet sel -N xhtml="http://www.w3.org/1999/xhtml" -t -m "//xhtml:a/@href[contains(., 'client') and contains(., 'linux') and contains(., 'amd64')]" -v '.'
# RUN wget -P /usr/local/bin https://storage.googleapis.com/kubernetes-release/release/v1.6.4/bin/linux/amd64/kubectl /usr/local/bin/kubectl
RUN curl -Lo /usr/local/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl && \
	chmod +x /usr/local/bin/kubectl

ADD scripts/* /usr/bin/
RUN chmod +x /usr/bin/*.sh

ENTRYPOINT [ "/usr/bin/run.sh" ]
