FROM registry.redhat.io/rhel9/php-82:1-1777884059

# Add application sources to a directory that the assemble script expects them
# and set permissions so that the container runs without root access
USER 0
# Kernel headers are not needed
RUN yum remove -y kernel-headers

ADD app-src /tmp/src
RUN chown -R 1001:0 /tmp/src
USER 1001

# Install the dependencies
RUN /usr/libexec/s2i/assemble

# Set the default command for the resulting image
CMD /usr/libexec/s2i/run


