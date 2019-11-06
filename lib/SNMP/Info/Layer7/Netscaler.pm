# SNMP::Info::Layer7::Netscaler
#
# Copyright (c) 2012 Eric Miller
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
#     * Redistributions of source code must retain the above copyright notice,
#       this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * Neither the name of the University of California, Santa Cruz nor the
#       names of its contributors may be used to endorse or promote products
#       derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
# LIABLE FOR # ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

package SNMP::Info::Layer7::Netscaler;

use strict;
use warnings;
use Exporter;
use SNMP::Info::LLDP;
use SNMP::Info::Layer7;

@SNMP::Info::Layer7::Netscaler::ISA       = qw/
    use SNMP::Info::LLDP;
    SNMP::Info::Layer7
    Exporter
/;
@SNMP::Info::Layer7::Netscaler::EXPORT_OK = qw//;

our ($VERSION, %GLOBALS, %MIBS, %FUNCS, %MUNGE);

$VERSION = '3.70';

%MIBS = (
    %SNMP::Info::LLDP::MIBS,
    %SNMP::Info::Layer7::MIBS,
    'NS-ROOT-MIB' => 'sysBuildVersion',
);

%GLOBALS = (
    %SNMP::Info::LLDP::GLOBALS,
    %SNMP::Info::Layer7::GLOBALS,
    'sys_hw_sn'   => 'sysHardwareSerialNumber',
    'cpu'         => 'resCpuUsage',

    'ns_build_ver'    => 'sysBuildVersion',
    'ns_sys_hw_desc'  => 'sysHardwareVersionDesc',
    'ns_cpu'          => 'resCpuUsage',
    'ns_serial'       => 'sysHardwareSerialNumber',
    'ns_model_id'     => 'sysModelId',
    # these will only work if lldp is running
    'mac'             => 'lldpLocChassisId',
    'lldp_sysname'    => 'lldpLocSysName',
    'lldp_sysdesc'    => 'NS-ROOT-MIB::lldpLocSysDesc',
    'lldp_sys_cap'    => 'lldpLocSysCapEnabled',
);

%FUNCS = (
    %SNMP::Info::LLDP::FUNCS,
    %SNMP::Info::Layer7::FUNCS,
    # IP Address Table - NS-ROOT-MIB::nsIpAddrTable
    'ns_ip_index'    => 'ipAddr',
    'ns_ip_netmask'  => 'ipNetmask',
    # TODO VLAN - NS-ROOT-MIB::vlanTable
    'ns_vid'      => 'vlanId',
    'ns_vlan_mem' => 'vlanMemberInterfaces',
    'ns_vtag_int' => 'vlanTaggedInterfaces',
    );

%MUNGE = (
    %SNMP::Info::Layer7::MUNGE,
    %SNMP::Info::LLDP::MUNGE,
);

# NOTE:
# citrix only has the most crucial support for standard mibs, instead they
# seem to like to duplicate everything in their own mib and under the same
# object name. this wouldn't be that bad if they wouldn't also randomly change
# object types, so we'll most likely need to duplicate a lot of code (or come
# up with a way to just munge_() the data here will keeping the original code,
# if that's even possible.

# TODO
# * do we need to handle layers, since we have
#     NS-ROOT-MIB::l2Mode.0 = INTEGER: disabled(0)
#     NS-ROOT-MIB::l3mode.0 = INTEGER: enabled(1)
#    (with these settings it still reports '72', layers 4 & 7)
# * reports no vlans (examples of where to find all data
#       NS-ROOT-MIB::vlanId.51 = INTEGER: 51
#       NS-ROOT-MIB::vlanMemberInterfaces.1 = STRING: "1/6 1/5 1/4 1/3 1/2 1/1 0/1 LO/1 LA/1"
#       NS-ROOT-MIB::vlanMemberInterfaces.50 = STRING: "LA/1"
#       NS-ROOT-MIB::vlanTaggedInterfaces.1 = ""
#       NS-ROOT-MIB::vlanTaggedInterfaces.50 = STRING: "LA/1"
#       NS-ROOT-MIB::vlanTaggedInterfaces.51 = STRING: "LA/1"
#       NS-ROOT-MIB::vlanAliasName.50 = STRING: "*** PROD-VIP ***"
# * reports no ips, not even management (where to find stuff:)
#       NS-ROOT-MIB::ipAddr.10.40.52.4 = IpAddress: 10.40.52.4 (virtual ip for server)
#       NS-ROOT-MIB::ipAddr.10.40.254.35 = IpAddress: 10.40.254.35 (management ip)
#       NS-ROOT-MIB::ipNetmask.10.40.52.4 = IpAddress: 255.255.255.0
#       NS-ROOT-MIB::ipNetmask.10.40.254.35 = IpAddress: 255.255.255.0
#       NS-ROOT-MIB::ipType.10.40.52.4 = INTEGER: subnetIp(4)
#       NS-ROOT-MIB::ipType.10.40.254.35 = INTEGER: netScalerIp(1)
# ifnames:
#       NS-ROOT-MIB::ifName."0/1" = STRING: "0/1"
#       NS-ROOT-MIB::ifName."1/1" = STRING: "1/1"
#       NS-ROOT-MIB::ifName."1/2" = STRING: "1/2"
# duplex/media info:
#   1/1->6 not pligged in
#   la -> link aggregation
#       NS-ROOT-MIB::ifMedia."0/1" = STRING: "Full Duplex 1000-BaseTX forced"
#       NS-ROOT-MIB::ifMedia."1/1" = ""
#       NS-ROOT-MIB::ifMedia."1/2" = ""
#       NS-ROOT-MIB::ifMedia."1/3" = ""
#       NS-ROOT-MIB::ifMedia."1/4" = ""
#       NS-ROOT-MIB::ifMedia."1/5" = ""
#       NS-ROOT-MIB::ifMedia."1/6" = ""
#       NS-ROOT-MIB::ifMedia."10/1" = STRING: "Full Duplex 10G-BaseTX fc none"
#       NS-ROOT-MIB::ifMedia."10/2" = STRING: "Full Duplex 10G-BaseTX fc none"
#       NS-ROOT-MIB::ifMedia."LA/1" = STRING: "NO MEDIA"
#       NS-ROOT-MIB::ifMedia."LO/1" = STRING: "direct connection"
# ifalias:
#       NS-ROOT-MIB::ifInterfaceAlias."1/3" = ""
# lldp stuff:
#       NS-ROOT-MIB::lldpStatsTxPortNum.3.49.47.54 = STRING: "1/6"
#       NS-ROOT-MIB::lldpStatsTxPortNum.4.49.48.47.49 = STRING: "10/1"
#       NS-ROOT-MIB::lldpLocPortId.3.49.47.54 = STRING: "00:e0:ed:7e:f0:46"
#       NS-ROOT-MIB::lldpLocPortId.4.49.48.47.49 = STRING: "00:e0:ed:64:5f:ff"
#       NS-ROOT-MIB::lldpLocChassisId.0 = STRING: "ac:1f:6b:44:0a:6f" (type "OCTET STRING" instead of "LldpManAddress"
#       NS-ROOT-MIB::lldpRemManAddr.3.48.47.49.13.49.48.46.52.48.46.50.53.52.46.50.52.54 = STRING: "10.40.254.246"
#       NS-ROOT-MIB::lldpRemManAddr.4.49.48.47.49.13.49.48.46.52.48.46.50.53.52.46.50.52.54 = STRING: "10.40.254.246"
#       NS-ROOT-MIB::lldpRemManAddr.4.49.48.47.49.17.54.99.58.98.50.58.97.101.58.57.49.58.49.57.58.51.48 = STRING: "6c:b2:ae:91:19:30"
# virtual ips used for load balancing?
#       NS-ROOT-MIB::vsvrIpAddress."LB_ActiveMQ_61616" = IpAddress: 10.40.50.12




sub vendor {
    return 'citrix';
}

sub os {
    return 'netscaler';
}

sub serial {
    my $ns    = shift;
    return $ns->sn_serial() || '';
}

sub model {
    my $ns          = shift;
    my $ns_modelid  = $ns->ns_model_id();
    my $ns_family   = $ns->ns_sys_hw_desc();

    # here you need to combine data from 2 oids, for my test hardware:
    # NS-ROOT-MIB::sysHardwareVersionDesc.0 = STRING: "NSMPX-5900 8*CPU+6*E1K+2*IX+1*E1K+1*COL 8925"
    # NS-ROOT-MIB::sysModelId.0 = Gauge32: 5905
    # hardware version contains the family, "mpx-5900 in this case
    # model id contains the model in that family, so this device should be a "mpx 5905"
    # note that model id will be 0 if the device has no license
    # i opted to just get the family and add the model id to it, so the final output in this case
    # -> "mpx-5900 5905". feedback welcome

    if (defined $ns_family) {
        $ns_family =~ s/\s.*//; # only need start of string
        $ns_family =~ s/^NS//;  # strip NS from start, need more hardware to see if we need more strings to strip
        if (defined $ns_modelid) {
            return "$ns_family $ns_modelid";
        } else {
            return $ns_family;
        }
    }
    return '';
}

sub os_ver {
    my $ns    = shift;
    my $ver  = $ns->ns_build_ver() || '';

    # citrix refers to their build id's ala "NetScaler release 11.1 Build 63.9."
    # try to convert it to something like "11.1(63.9)"

    # TODO

    if ($ver =~ /^.+\bNS(\d+\.\d+)/) {
        $ver = $1;
    }
    return $ver;
}

sub mac {
    my $ns  = shift;
    # lldp.pm has fancy ways to determine this for remote id's. netscaler gives
    # us a preformatted string with it's mac. easy.

    return $ns->lldpLocChassisId() || '';
}

#sub ifName {
#    my $ns = shift;

#    return $ns->SUPER::ifName();
#}

sub ip_index {
    my $ns    = shift;

    return $ns->ns_ip_index();
}

sub ip_netmask {
    my $ns    = shift;

    return $ns->ns_ip_netmask();
}

1;
__END__

=head1 NAME

SNMP::Info::Layer7::Netscaler - SNMP Interface to Citrix Netscaler appliances

=head1 AUTHORS

Eric Miller

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you.
 my $ns = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          DestHost    => 'myrouter',
                          Community   => 'public',
                          Version     => 2
                        )
    or die "Can't connect to DestHost.\n";

 my $class      = $ns->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Subclass for Citrix Netscaler appliances.

If you use what Citrix calls partitions you will not be able to get the complete
data in 1 SNMP::Info run, since there does not seem to be a global table which
contains data for all partitions. Instead partitions should be viewed as vrf's
which we currently don't fully support. Due to this we will focus on the main
partition, either C<default> or C<management>.

=head2 Inherited Classes

=over

=item SNMP::Info::Layer7

=back

=head2 Required MIBs

=over

=item F<NS-ROOT-MIB>

=item Inherited Classes' MIBs

See L<SNMP::Info::Layer7> for its own MIB requirements.

=back

=head1 GLOBALS

These are methods that return scalar value from SNMP

=over

=item $ns->vendor()

Returns 'citrix'.

=item $ns->os()

Returns 'netscaler'.

=item $ns->os_ver()

Release extracted from C<sysBuildVersion>.

=item $ns->model()

Model extracted from C<sysHardwareVersionDesc>.

=item $ns->cpu()

C<resCpuUsage>

=item $ns->build_ver()

C<sysBuildVersion>

=item $ns->sys_hw_desc()

C<sysHardwareVersionDesc>

=item $ns->serial()

C<sysHardwareSerialNumber>

=back

=head2 Globals imported from SNMP::Info::Layer7

See documentation in L<SNMP::Info::Layer7> for details.

=head1 TABLE ENTRIES

These are methods that return tables of information in the form of a reference
to a hash.

=over

=item $ns->ip_index()

C<ipAddr>

=item $ns->ip_netmask()

C<ipNetmask>

=back

=head2 Table Methods imported from SNMP::Info::Layer7

See documentation in L<SNMP::Info::Layer7> for details.

=cut
