from pyasn1.codec.der.decoder import decode
from pyasn1.codec.der.encoder import encode
from pyasn1_modules import rfc2459
import sys

# Usage: this script takes 3 arguments:
#  1 - Certificate to be altered
#  2 - Destination path where to save the altered certificate
#  3 - Certificate to use as reference for altering the public key

with open(sys.argv[1], 'rb') as fileInput, \
open(sys.argv[2], 'wb') as fileOutput, \
open(sys.argv[3], 'rb') as alterationReferenceFileInput:
	certificateToAlter, restOfCertificate = decode(fileInput.read(), asn1Spec=rfc2459.Certificate())
	assert not restOfCertificate
	referenceCertificate, _ = decode(alterationReferenceFileInput.read(), asn1Spec=rfc2459.Certificate())
	certificateToAlter['tbsCertificate']['subjectPublicKeyInfo'] = referenceCertificate['tbsCertificate']['subjectPublicKeyInfo']
	outputSubstrate = encode(certificateToAlter)
	fileOutput.write(outputSubstrate)
	print("Finished saving Alteration 3 - Public Key in " + sys.argv[2])
