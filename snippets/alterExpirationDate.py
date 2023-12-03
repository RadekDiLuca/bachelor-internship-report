from pyasn1.codec.der.decoder import decode
from pyasn1.codec.der.encoder import encode
from pyasn1_modules import rfc2459

with open('server-certificate/serverCertificate.der', 'rb') as fileInput, \
open('alt2-expiration-date/attackerCertificate.der', 'wb') as fileOutput:
	certificate, restOfCertificate = decode(fileInput.read(), asn1Spec=rfc2459.Certificate())
	assert not restOfCertificate
	certificate['tbsCertificate']['validity']['notBefore']['utcTime'] = "010530070422Z"
	certificate['tbsCertificate']['validity']['notAfter']['utcTime'] = "400530070422Z"
	outputSubstrate = encode(certificate)
	fileOutput.write(outputSubstrate)
	print("Finished saving Alteration 2 - Expired Certificate")
