ME=`basename "$0"`
if [ "${ME}" = "install-hlfv1.sh" ]; then
  echo "Please re-run as >   cat install-hlfv1.sh | bash"
  exit 1
fi
(cat > composer.sh; chmod +x composer.sh; exec bash composer.sh)
#!/bin/bash
set -e

# Docker stop function
function stop()
{
P1=$(docker ps -q)
if [ "${P1}" != "" ]; then
  echo "Killing all running containers"  &2> /dev/null
  docker kill ${P1}
fi

P2=$(docker ps -aq)
if [ "${P2}" != "" ]; then
  echo "Removing all containers"  &2> /dev/null
  docker rm ${P2} -f
fi
}

if [ "$1" == "stop" ]; then
 echo "Stopping all Docker containers" >&2
 stop
 exit 0
fi

# Get the current directory.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Get the full path to this script.
SOURCE="${DIR}/composer.sh"

# Create a work directory for extracting files into.
WORKDIR="$(pwd)/composer-data"
rm -rf "${WORKDIR}" && mkdir -p "${WORKDIR}"
cd "${WORKDIR}"

# Find the PAYLOAD: marker in this script.
PAYLOAD_LINE=$(grep -a -n '^PAYLOAD:$' "${SOURCE}" | cut -d ':' -f 1)
echo PAYLOAD_LINE=${PAYLOAD_LINE}

# Find and extract the payload in this script.
PAYLOAD_START=$((PAYLOAD_LINE + 1))
echo PAYLOAD_START=${PAYLOAD_START}
tail -n +${PAYLOAD_START} "${SOURCE}" | tar -xzf -

# stop all the docker containers
stop



# run the fabric-dev-scripts to get a running fabric
./fabric-dev-servers/downloadFabric.sh
./fabric-dev-servers/startFabric.sh

# pull and tage the correct image for the installer
docker pull hyperledger/composer-playground:0.16.7
docker tag hyperledger/composer-playground:0.16.7 hyperledger/composer-playground:latest

# Start all composer
docker-compose -p composer -f docker-compose-playground.yml up -d

# manually create the card store
docker exec composer mkdir /home/composer/.composer

# build the card store locally first
rm -fr /tmp/onelinecard
mkdir /tmp/onelinecard
mkdir /tmp/onelinecard/cards
mkdir /tmp/onelinecard/client-data
mkdir /tmp/onelinecard/cards/PeerAdmin@hlfv1
mkdir /tmp/onelinecard/client-data/PeerAdmin@hlfv1
mkdir /tmp/onelinecard/cards/PeerAdmin@hlfv1/credentials

# copy the various material into the local card store
cd fabric-dev-servers/fabric-scripts/hlfv1/composer
cp creds/* /tmp/onelinecard/client-data/PeerAdmin@hlfv1
cp crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/signcerts/Admin@org1.example.com-cert.pem /tmp/onelinecard/cards/PeerAdmin@hlfv1/credentials/certificate
cp crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/keystore/114aab0e76bf0c78308f89efc4b8c9423e31568da0c340ca187a9b17aa9a4457_sk /tmp/onelinecard/cards/PeerAdmin@hlfv1/credentials/privateKey
echo '{"version":1,"userName":"PeerAdmin","roles":["PeerAdmin", "ChannelAdmin"]}' > /tmp/onelinecard/cards/PeerAdmin@hlfv1/metadata.json
echo '{
    "type": "hlfv1",
    "name": "hlfv1",
    "orderers": [
       { "url" : "grpc://orderer.example.com:7050" }
    ],
    "ca": { "url": "http://ca.org1.example.com:7054",
            "name": "ca.org1.example.com"
    },
    "peers": [
        {
            "requestURL": "grpc://peer0.org1.example.com:7051",
            "eventURL": "grpc://peer0.org1.example.com:7053"
        }
    ],
    "channel": "composerchannel",
    "mspID": "Org1MSP",
    "timeout": 300
}' > /tmp/onelinecard/cards/PeerAdmin@hlfv1/connection.json

# transfer the local card store into the container
cd /tmp/onelinecard
tar -cv * | docker exec -i composer tar x -C /home/composer/.composer
rm -fr /tmp/onelinecard

cd "${WORKDIR}"

# Wait for playground to start
sleep 5

# Kill and remove any running Docker containers.
##docker-compose -p composer kill
##docker-compose -p composer down --remove-orphans

# Kill any other Docker containers.
##docker ps -aq | xargs docker rm -f

# Open the playground in a web browser.
case "$(uname)" in
"Darwin") open http://localhost:8080
          ;;
"Linux")  if [ -n "$BROWSER" ] ; then
	       	        $BROWSER http://localhost:8080
	        elif    which xdg-open > /dev/null ; then
	                xdg-open http://localhost:8080
          elif  	which gnome-open > /dev/null ; then
	                gnome-open http://localhost:8080
          #elif other types blah blah
	        else
    	            echo "Could not detect web browser to use - please launch Composer Playground URL using your chosen browser ie: <browser executable name> http://localhost:8080 or set your BROWSER variable to the browser launcher in your PATH"
	        fi
          ;;
*)        echo "Playground not launched - this OS is currently not supported "
          ;;
esac

echo
echo "--------------------------------------------------------------------------------------"
echo "Hyperledger Fabric and Hyperledger Composer installed, and Composer Playground launched"
echo "Please use 'composer.sh' to re-start, and 'composer.sh stop' to shutdown all the Fabric and Composer docker images"

# Exit; this is required as the payload immediately follows.
exit 0
PAYLOAD:
� @w�Z �<KlIv�lv��A�'3�X��R����W�G�i�-��H�%[v��fw�l����H���\� �d�A� s	r���@����!� s�)�`�[�WU�f��,˖��fܪz�ޫW�W?*�|���ltM��S�m�pu%:�jW.�ġd2)�o2����%ɧ���D��d��d�J��$��+(~A��[\ۑ,��8�t�ڧÝ��-GزUCϣ���gc�H����8�<����M��Iձ��K]��[i�ڕ�P���Ұ��Vl�P)
j�c3�E����b<O�w�ӱ�3�Cڪ���j�}[����s���roZ���Ғ��*G|!���p�Ƴ����ŷ�4|���N^A��dJy�����8˴>jw.������������L<�'��Ϧ�3�e��XS�cM��p��Z2F�[HV�?�j_�O������N�(>�?~F����d����k��`���K���K ��u��T&D�P$bZ���I7@�,�}YM�ꛖ�7�L�K�b�tA�J4;|U/p��' ;��D���pf��P����#b����I!r:��U�FIW�����J�,W�U�=J
m��d;�y�6������[
U!d�(��6���#b�[<�GK(F���:�vX�(��n�N�	#t#�)����tW�H��(P>)f����8q)H=q*�:�������"D����Hq���͒m$٨��/1Be�5bڃg�l�Y�����2ˆE��L>0td�����Š�Q��X�@U�����VR��	2tm@����>l!�V�h$P����%]�Uډ��9p: (�mm'��[�l�l�a�A��*w�aҹ��9�i/ݢ��n *l���Qٓy���<D��6��� ��&؂��\�0޲�I��5�C�ia��޽�e������5��}���-ɜb�x=��2%��� g��|"1��gS��,�_F����M�hV�S���h./����g����!.af��PX�T�GX3�.���ٲ��jA�7%�#�eh�$�dwŒ�,Is-�  �ُa���h��������Vc�spM���evuoaps�i ��M`i�+�n�/�z���+ַ˛�gcYs�lD�q�����z�$��Po�7�qs���cpK�C1"9�$}��;�g#^�>�T������İ�.�OGk�a��z�X���8#Y��\o���=��ؠN�zl�|ݲ1�b�>1�q��i6��Zx���#��wn�
`�#��Z�Jx�Gh����c�O͍Oe5�������v��
�Oo$�Ѭ�/�����'V��s�� �XxR- $<n�Y�,��qx��7%�V���/����ԩ���3��?����K)OAg�Ľ��(|R�wI�wHH@��x��Y���VzM�X�H�����'	����ࢌO����L�";a�R�$���X.�U�v���}J�5� �A��wY�ki���8���Š��6��эM=�tC���?tF	I��1,:�� �;�?M�1x-$��tp$���C<��bC�#�R��˦fȇrGR�a�mh.�, �<��<��H�Jv�-WGMWՔ�d���A?^K$�j&�D�?-U�(��:F*��G���)a�
�e�H���h.�)��H�XeM|4�a����&Z�}���ܳ����s�����?�����(����]����E����g2q~f��Qf��v�)�/[r�-�-A��x��Ws��D<����K)3��˩�?\�nYY)��8������q~v�w)���^����͆�GSՉl�*ش�m
jYFţ|:GȻ����c�9��*S�b���i���w6����_F9{���*jp������'����_By���Wg�2����ff�������"9�4t�R-�Aز�.2-Uw��ݮ�+v�#g��q;��Ʒn���;�?hKE'4=�(�?D�s��'�m����aE���v��a�>yt��H�m�u�	�S��i�
>�]�K]S���(;�}�q[�e�}�j�������Z�G�����|[1��9v��':���"�����snU��*W�7��1�	\ͤ���HEa�3ޒ��_�,�c�����͹9���n���<�,Z�,pk�c �%&���EO��K�!�W��r-�	�����.M#��_ӽ�݉��ui��.�����b><ԋ)�o[A��Q�w�᜽iO"*��4�"-�2e��&�(��⚠D�=I=���p�T���b�j�Hǿ9�A�l�v{�n��ϽK�&Y����w���06	B����ϐw[�p�3��&��@��ca�s�i��4�gj֑tk�w����LXģ��棘Y69��Cxo	�"xX��"% ����q��Ǥ�^031����zKm;�ѱ�u���5C�Oc	�Dtl��7����jP��*nV��+[Bcu�]ی���4]}6I� �_H0��Hsr�Qz(}~[�鮲��l�ɽ|�cn��7����[Z^8�{�[�g����d��L��^Ny��om��m���/�$̣-�{"�Hm��D�鯒��Q�*���&�t���瘧a:�G�h<b��Y}d��=d������M�p����ţ�hf�Ͼ���y��u����0[�_F9�����@z�_�y��O>�IN�*={�s9Rl�Xj��r�Yf	�O��FuL�B�r���o�D6ح�HY���TpLht��H$��_p�����"���Z�����%ч�&��QW�&,yh �l�l˄}���ldJ� �<3�랲�1y�kh��E������0�d>��V�_�AȫϏ�|�I}쵔����c �V[��c�m��5���@����NT��D�!�#��(Ϡ�Sm�c�.�UH~
�)t}0�45U�Ԧ�&����F_�Roc�<?·��}5�^�+���J��Ͼ�����Tj���m�9sO�4���´����T=��E_��O����
]�B�?6IG�F�Mvk6aF*;���� ֒���J�_q����3��ع��ȶ ٢0���h�L�l�oL1�y��O�]�ap<��7-6[�N�!��h�Vu����1$��e����S�?`.��\"��,�(V"���`�>h�� � 
���Z�{�qM���xC���>�1��1T�x`:F����2�&�0�9����Z�\Kutւ{B� ["[�\�US��n ƊX)�un4�����6�Ŀ��D���Y�.x�����ݣ=���r�@��1,r�?�a�Mc���g����S?pA�a"�ɖa���h�6|�&]������}T�0�G��������a��Mx�EbD�ǆ����{hb��a��U�v�l�M�-�my��d��E��(oV}pv������H �%���Ǻ-�n�E���zZF"�F�}���mX��;r?�{�«FX:�a��gP%3C�T���n���HR5z�D^A<�����1�tW"|(��0�H0
���¶��9uz�nAr@�j������K�?8��7ޛ��ݞ�?f���/�C��H�8�m��<�>�e��.�L�b��AU����)���"�Q����0c�+�ծ۝F К���P�΂�S�&�=l2>�&4�#*L���jX�n�@�.�Gn#V�_�-U�`Xʈ�cё��H e�pnU
A�h�e�	�L����C°y�;N�ƇT��G�d�`�6M ��1�Y��<���|��Id��I>@�`�$< ÚjS��0�������<�� bW�vl��[yz֥�xn2�5��D6J9�s�\b�)Qs�Yo>L�0��xJG%1���z���x�!S���z~c<S�p�8q�rB����+Dtcڊ�uMvp�/8ᗵ��2�'?Ϡq���x:;y�?�I�~��R
���p���k�\��?��/~���N��N6�r*��-�d^�S9��l���\.�j��DV�)�2�\3�L�R*����fv1�h.�ӡ?z���;�$��M���5��Z&t��ǍvyB�~�������WC?�:�䋫׮����ܻtub����k�
qÿ�Cf_ ������F�hί��1����*�0{���oz�Yy��|:�/�<g�����I��$g��y9�_Gɕ�3?��ܟ��_��귬���ݟw~����������|���!�}�s��s�ѵ�߽
��g�W�G�]��U���T&��T��RI%��b>O��M%��p&��7�w�Sr.���E�O$�-i1�P���"t=����~�u��O��O�_.��˿��6�J���1C�~�n<��r�6�C�a��N3��}��<G��\����oU��B��~���C��>�o�$��FH)�+�**��Fy�\"��*�r�vP,
��z��.�Jk������G[˭�}��+���B���sx��U�����q�f��bm��[�����ݝc�QB�#��Zbٖ�?<��is�!ޯj��ЯTw�nY|8����Ճ���R�Y�N��L�����W�y��mt�G͆(W
����^Bt��^����c!Q9��Wj���C	�����q��J�x,���݂����F�^�lhe�g����͇�ܠ��:��^oY�m�b�o�R����iv����Uꇽ�X����������ʎ���9�z��Ҧ0%N�W�����{boou�xX>>���^��.	5�Tk"wXK�Bi��оS>^_��ƓNl#f��N��dϴ��c��)�L�ְ#,o����W�6����r�h��;�+�� �;R�UY��J��z|K���
�}{�[�,(k �������B�ԣ���zb!v,�D����Xn��+��=��b{5�nCx"=�r�ҽ�������ƞ~��OR�b��Z�ʺPn�AL�9p
{�خ8\?�����;�N�LmE.��o��by�&�3�����.����46�Ρ�^6qC�j��⮽�i���Is	�əִB�I.��.T�M}�zg��
+�AV5�C�69��|,np�YH�R�ݭ��c��Բ�(V;����J�������Fi���
'w�Ak���b�!<` FC\�����N�A�~��>h&��Ւ��]]��Xz�F��wvv��jv;�f2R>��o_�����`������ۘo�����:w����2׹̿���OLTMQ]�]�e{���Re�s8��<��=��9�)b��M�=1�M5�Xɘj�Hݔ1+96:CN� k��fx*1@'f�E��!W�>���W6�-����s=H�T��-%C%�%��~��YNZ��[NG���0������NЭZ#2��!d5M���jc�MO�-�kW�j�A@�t��-b�����F���N����4�����!���zҶ_`�ch��DvĲ*{��c���27]��5�����q\�.S�ud�^_!|�RL!+�m�Uv~��C��,⳪��e�'ªNA��/�f�%J��!-�zEZ�IטY���l��˾AV��TSv�yy..lQ�U�^P��V6�x��7��d��@�྆�0*,V�2�����y��Bv��#n:&�d���4��L��lwv�L���7p�Zi�����!�J���C�Ğ���R\9� ��q�C�����:Coߠ�3�)���rX��C5<
�e���n�)�sƪ`�A����Q�`	!�%SD�e�f<0��
��xn{�N=~�S�y��C��W�Y�@l�i��fߩcᄨ�mv��Q��T��e���Sc+����Z,3��N	�'�zȵ��<�Z>�H<RJ(9�e�S�ٍ0�*c��z�P�^��r� ��{?ݔ���@/;6�l����K�]�U�����_}���{�V�����W�|�]qv��~s������[�������[�:���������3	��_z�?�����W���E�����
��]�n��
��]�A73̅����������m�_�-�˷�瓃��(���*�71_�J��\��v�H7;��s.b�m~�_X��y�n�w���bL&]��\�ST�z�'悞��o3tE]z,���Gw��r���P�D�X&kr�s,d�&p�k<��x�ۣ�
��xJ)
��[�C5kS0ST�O�߭�)��աC����:�B��m�`Òg�;Ӳ��Bi��RuL�~�2�c�?�e�{b�ɡ9c���cV`�� g�	�V`�?~����}q?8���IE�]��Ȗ��mwB�l̇+w�{�
�$P�Z�8�ؠ��ƍ��G�ak:m���vhbܩ���}X��V�@���d����𐛹Cb�{�Y͒G
;�:1��N�������h����?e����ܚ��VK�z诇��E�_|���R9��kwry϶OY�j�S|�ν�#:�)���i#q�	�6���WǄ�=k��=����;t��#�{����<�[��.�[�n[Ƚ��G�(�r#����Qk`])4�Z�'賙�j5�8���p�}y,׬�Q/nN{z0WK]n��R���pOc)���4U�	�.���P��2��l\��,#��cy���t��s_o�_�l7��[ik��<���Ƶ�r��%E����6uyȪ���tJW�]�b���`!*�Q ��xj/{�X�6�����I�����J �4�9�]�3D�
�"���伤��?��&��G��f&�dwHTm3��N@�U��j�����$���y,�ׁd[>��	��!U���z��)�@7:��`b��)�49
(�m��x@1����N�_Cjb4D�AV'�TdV���"����6=ݐ}L��jOX��j0�E5T�&�ּ=��ɾ��Pi?\%�:E�{
ݪu�%^���l�.�g��+���ő�ma�mB��w��P8lX����B���%m��l��l�f
�tѹQ<8L.h�6�.����X�m��dg�z��uaR�Lg]����(���_�ҥ_��-��ag�����7���/:k࿆��֢M7�V�q�8,�:���o�_&���,\����7�/�/�E4�S~������/^A�����o����9�������u��s�ff��_q�F۞��9��z�٤Gg�Ο��A�T�0ٳ�����Ni]S��>� ��x����j}L�N>�W�w��Χ��7׍s^�T ��߾m�[�H&��+賫 �'���dI黼������ ������Z�;����_����x���������?�a��S�����|�ׂك�8> �����O%�]@P���Ͼ�=���	N���ϣ��{���)���_�*��6ނ4��	�O��4������O!8��4��_ժ��������?u��@�����?�c��� ���9�c�=���O��c;��l1�D ���9��$����Ǿ�����77'ҟ6����?��]�?	�� H� i m�}�6�����=�?���@��/�����l���'�Y��SAN���y0�r����q
��4 2�A���@Ϻf�\�?���$�i S�MB� [ ����_.���/�?�?����*�ԑ�w������O�����m=��V�=�� ���̐�������g	��_���������`@6ȅ��������0��r����@�e�L���݅�|�������/�����A�ߔ��w(E]�_���0FS���`.�x���K���%u��>c�!	a��QD(���s}w?u��q������tp��7�r�`����ݓ��*�/�m�IHl'c��S�~�R{G����Ъ�Q6Y_T1��,ઋ�m����l2]m�3��a�N鶊X�[�J!���m�@�cH�݁B �j�
gLȾj��,F:������xo'W�&3F������������A���Y��&`�7�C��/;��A���)�_�⛃��cx�����>���l_Ťu���,��!PLW�1�++�|ҭ��:*��~�8�����Z�O��j�D����S��Ё7��f��ʛ��*�/�^k��\��"i<X�kf�������b���]����`�7#d�����?՟r���e���@����?@�e5�4`vȅ�#��G"@���G���_�F��5?Z��?��^�H"g��'���ݏ��nޢ�����.�c��zwۣ۠m,"��:oZ:� d��E���b�-�����N�.q��*v��*.��о8_0I6;�F���R�؃n��Z(����A��Q_��*K\�����IS�����Z�h�W��8_,s�#��.��J��{Ԃ�U�D�
��X��w�|�%tK���Wf�E��^����SV7��d�Y��t*tٸ���n)yH.�v�0�W��h=0�R���m�/���	�땭�6�O^��F�Jܳ��T�����k������!�������4��'��P�%�����kn�����!���� �O��?��;�����+�M`�W��+��������.꿂��RB*���[ ����_�C/꿂��)!m����������'Q��� X������`�?��@�=��������l����?;���`��|!����_��S�����y�ȃ�CI��_Vx��}p��D�������� �O_������� =��~p{�Ą������!���R���@���Cd����3�0������% ��Ϝ����������i!Y -���8��)������ �?d�����_*�^���rC2��/[���I���������������``��T���$����?�ҚW+È5��Tj+�o���'����G��q,����ƙ6'δ�;��<�]�r�)m�e���VDcV��a�$�S�\Qz�E�Pe��a�Q��7�!9��K���w��P��Cs��
N��%o8#FFjm��9 P��!9 P��PH3f����[�IqȈVGev#D��Е���t;Ċ�r�lf�a�:/sd�L5�h)��E���rc���8��>E�^յ�?��;��ȅ�C��������(�%����/�O^���H	��P2u����S��?�����#���?��_6������l����?3��Aq�ԑ���3���?���/��(�_F�^���]�W.p�Y ��������8zY�! ����?��c��Q�c3%��H�H�O}��<CJ�K����4�y���i�eJ46��?�������ǩK�����-��h��-��*vO�_���Ȫ�*q��d�s�]���ǱX�$$���]�M�G1+�k�ނ�Cm	ٛ�f��v�;�f]��e�1�a�M���]q7�`pu����W��-��j�'H�r<\��mk��@��� +����[I��
܋;��Xj�(�2ң΍߻���?�!�������h&}�E�?��!��d�����e�l`֟�KD�����1���ZO���oH
H�Ǆm�8mfh���az^pq�˓��~G.[�[,Q��g��c�V�Hh��Mv�M�+�	v�l��k���Fu��3m�<\��$�:������G����B�$��i ����o�է���,���_ �+3��/���@���/���3A�I�@�e������?��������٦��XYQk��.�u����u�����V:%��(��pmOD*Zڶ^�zQT�8Ԍ�dm����=�'ø3��hGQFge�x])2-oOڵ���~-��ڲ�MF<7��T�A���l6���:�;ޫ\����*l��	����\��w�B�%�(��?췪�RI�E����wn͉�[��X5r>\���*�(w�=��������ӓ���L��g��҆�;������C�Wt9l��^�S�b,��zhIx�u�_lK��O����/��w�ь�k =ѵ�/b/H$��Be�vGK����H����9�!]�����:i^�Y���b��D΢��}w�	�#�3���;�m����.`�t�����Y���_�!�'����E��0ӫ����w��b	
���/����`����ﳞ�L�Ft��<O�Tʓ���7b�1\��a�D�<~�Ltb�`Ȁ$��+/P���y���?������������J$f�	�S��N�2I�F�D��o��H'V��ٷ����ܢ�a����:<����������O�������UWP�����B�u��y�����?
�?ަxTr)O�d �TDחi6R�&q�Mӈ�)!(.d#&P ���,�'Q���ŀ�C¯�-6KE����,\�8���n2
��`~H:���3z�S_J������?V+c)W�U+��{+�x��$�U��?l��)������bhx�� �������n��?��M�R�_����]��!���_��]F�������X
�?
�������OD ��(nߵ�x����g����:�?�?������L���^�@�����W���@�?������߃��?����*�����U�_������y���GD��?
�x�y(�dP����$^�d�P����\��d�\�5hu�ޔ���~���)�n)�^T�̥�9(JL�K�J���1��ѭ�I�Lc@����ъ�L�3���V�dZ.�>��&3��<�(�)E�/������!�*2����ʹPa�/|{fj��a0��~s�[���[�I�������fEb�驖��/�E>��-$�N��X�bt��*�n��n�P|f_:�ɦ0��ޚ�nk�,��^l�:����^�m�8$��1Qm��^�L+5�x�ʞj����.I�Ue�+S�J�:���'*&�o��Ŝ��n)�D^�ͽ��V�l���~��
%�Ƚrp�m�]a~�)�9��8?w'�E:�l�U�-��-mQ���n�\��4	���c'�_2�Ƭ벻F���"�Z���=d�����˰���{[T׼x܄��;�;C�$��R����VV�����o��CB�b��!P���v�W�g������P/�|$>�:��d_�?��D����z�����Co=��)��|��re�����.���Ku��s���
g���A�!����ܯ1���Xw���R�F��D�5�I��񞣓�����k��k�7��[.㣩�9��C*#5%���(K�j���ǈ�3���]���뢤x�$uq:�(�9k<�ޜٳ�)��NG��݅7▶�NC4�A<����9S�xk���m֧������q��)�*�Ԯu��p��Z��g��sQ4o�����`aʆ�K��8I�lgw���nV�$҃^o��m֜�F���`���멩�DSqe} Ӆ1`1Yɶ�3Ih>��'4�k���t&�=�	G9nfz6d6_Y�s��se(zi
�a��G����Y��[�-���]o���/ ���C��4  � ��k����A��"�f��	 d���3���������a�v���~���a��B����K[^�_�������i�O�w��݊ �I �4F�|� {���5 ���E�>���i��: �`<M/}���m����Dv>aQ��{����c[�O#q�i�;�l��3Og�о].c�?�d�)� e��� ��B���p~.�Yh<�W���q�,������$".�ْ����}��ڑzvP��+�ɘ�WHn�l�'^&�������uq���ckii2QԞ1�����vQ����4�WG�])�K����ʨC��>����������2j��P ��:�8��8���8��W[�D-�?�A�'	�
��-�s��w	������_��"����Z�?A\��O86L��)�Oy!I#:�#�&��"��<�h<
�����@h��`Kܻ���?����r���e�+��)�!��=q��qb��ry\�[It����<|��f�r1p-{c��K;���eD��e���G�<��3�^&�;�Hu��So�����	Db���ݖ���*��inʰ�������?�����~	��UR��?��ꨅ����ʨ����?�6��w��Q��W����#�dN�}�)ۍ�����n��ڼ_l���m�ڟō���?'Y쇇�Һ4�^�!w��ϖ�� Oq�:l=KNĩ�o��� �;[�L'��*n�[���Q䦙�8e��v=�O���V���� �[ux�G���w|s�ԡ�������������?�U����j�����?���������{�'u�%{�]ǃb~�lp���v��{lw�Z�/�*�	��@�-3��M��-6N�l��a��Cm�	3\#h,n�[o�kE�C�H���cq��=#�3c����e/lS���󬛱�B�='�
S�K�ul�e���ی��['���n[*M��wa'eJ[���Ĺhb?m葁�5���X�q$�B���w�D��2��1kܣ��¢]�x�,��2�u�;��Vh��3I��qH��X���[��'?BC�.|C�I�=�)b-t�\'�l��7bA$�l���Fr�R�f��0�v�߷W���� ���@����5�����������$�B��W���@��0ߵ�����W��$A��Wb���5���w�+�_� �_a�+�������W��p��D��x�)���v�W�'I��*��Ê�:Q�������$@�?��C�?��������?X�RS��������:��?�x�u������0�	����������G�!�#�����	��Q ��������א�?��$�`���4��u��������/H���������4�c^����WD���!Y&��y���� :�!�����y�O� �o� �$c^Hh.!6H`��gQ��h���H����^xX\��LVS�!1f���(�ZVIO�툾��I�&���ah���&S����B��|��>~�j��Q��zEI��lU��=�T����;�X\t��+)k4�uI���d���ή�S�6�x+ux����<�Q�@��>�����������QP�'�����	����j	*����������?�����j����U��/���j����c�*4��aJ1Q���D��<ΧTD1r4��x�4Dp�)���?��LC���_��/��x������m�-�9鶩���г�G�'E�?�����g;i7��Mm%,V\�h�#�v����>f�����lNL��&�Tp����l솝�|����t��#
��8���馹lA���������@���K���������S��GA�����i� �����W�x,T�?���� ��_�P���r�j���\����$�A�a3Du����W��̫��?"��P�T�����0�	0��?����P��0��? ��_1�`7DE�����_-��a_�?�DB����E��<����``�#~���������O�D:�r�S�4��r�g�������������������ٔ����~���}��pe�'=\&^j�K3ۆ���^�C��6��]����F(W��(�.�YI��ů��Ǧto"��յ�Z��O����ODS,���r�	!��Xwk?��A���_l<����j��oh��h�3R���A	�s�w,�NZy��L��I%YMU�U|(�Ğs���p��$����}a��KlUĺ �}F�G�heM���7j���0�u��~X^���� ����Z�?� ���P3��)Q����4��f��� �?��'�����C�WU���r�ߎ/�����B���WF��_�}�_��Ȩ������������?����-Z��zd5�qSR������b9x����t1S\�=�ԔG#�\D�n�3G^X�P]����xʩ=���"�5�~n&�X�j_���2!���������ٿ(<��c����<$����5�����^Xj��2����:i::�stһ�6z~��Rx�e|4��=�2~He���(Ko����c��Y
���n���뢤x�$uq:�(�9k<�ޜٳ�)��NG��݅7▶�NC4�A<����9S�xk���m֧������q��)�*v���Y���jYK4���mJb�+�\M�x��z9X��!��j�N�%���Ei����0������r�5gd��� 8�b��Ǻ�:Y�3�T\Y�taXLV�m�L�.�	���op-�I�k�-G�Q������WV���\��^�wb㑩�|v�i�;Ɩk�p������?"���"9�|���G�����A�)���G��H����iHpQ�q��D��LH��B��	�!E|Q,�\DRa�S1�@�x�Î�wS�8��?~��������i&��f�i�X��qwN��(4�c����x����m�������H��c�L#��=˛!oTl�?���=m\ٟ��B��n���&!a7{�$4	P }d�~9����ԏړ���I66�@y�{P�/[�F3��43O/�돷�w7�aGF�ҳ�Bu`jZ�z~�J���T{��`gp�F��N��M��u�sX�7�?��<����Kߧ,�a������<�����d�9��q��OM������f��t�g���ƻZ�=���1>
�N̽h�wK�����S��WW�N�٦���j���f�}e�Jiژڻo�Ǎ�G4�%5��'M�Tn/���A�=�s��z���z�O��}�u��a4ٝ�J�ûZ)}�Ou{;��ߺ�y���������+4�X����<��M��ӕM��&�k����ڜ�l�'>��؀OP����������{��������`w���䝣J�2w��pz[�Դ������I����T����h�1���?�  �g#c �TU����U)�R�a���һ���o���R�O3w��4�����k�>L�O�N꧇�U�SmU�(�׃F��i��c���.�4��^ժ�N�/�z{g]�7ct5�P&��Ż���@����V0���ayrV���U��`|�JWk4��t�Z�qt�\��e�8�[V�2��{{���\�i7��'�Ye 2�{7<+��e��c}=��J��QTX�4PJg�w�z��I��rǇ�=�}�E)����丬i�����3w��?�Ϗ���iI+_�����-���<;�p>�}؛nˍL�������s������ON�H_��
��[�g��?��/l���R^��9�Z�`�z��Y�$)�:i�3���5{{A:���ĩ�0�f���G�k�*�Ҙ*C��&�P*&~^h�2�[v�$H��5CC{��}b�2�h� �6�0Uf�d��c��\�Ov� ��AG�聐�9��Q$��?��}#�xg�>��HK؏6�1ݜ��i�4:s�i�:������G$̱i;'�䝟���x��b4���=L��e^~ƹ󻎇f��n �#P��j6����1	3hOg𘁜�uM�� �m�dj���'�i��|�$��t�M&��	ŮL|D��G�FH�� ��a���Z�b���r,�� �k�����5D	�:��R��R�^�I!��쳫YL�&�!�~���U���`��U>�� �
��4o�jr�A�m�.P��#��2��	6���U�0\�m��+O���՝7bv�0�b�b���ׯIo�wwI�&8��.~/��P�=�B�@���0��e�828f4̖�������=FF�a�4�`�ж��7Mx��Ĥ�S�'�E��P�3u�����ɵ��=jS��6@�B{P'���<��p�œ���/`ڙ�/�\�B
$��12-&U�3�@"��X�R�d�]4���O%@�xԗ�䢔�y�kF⸜���Ҩx*�k8���v�L��L.K��`�JH^�F�o�K4�\*5Ce��U�oKpr���8��+�&�rG�GQy���v2$�$�׍(QR"a�!#�q� �TݵA�@Wx��f�g:C	O�t�C��)�� a��q�ܛ�
4: �R����N4G^1u]��qN7�㈘�"�ȯ �H�"���D�[�:�����:N��Ԑl�p�t����ɒ�A7ġ���(��&��SU�v���3�<F|�s�b����T����߱erz�����Nnw.�Kv7��l���QpƁ5��e�e,�, �{�Cy�ki#: �N��ҙ: ��,���V�]9m�I��"�3n4�4Ш���K�v�rY)]7�j)�(�H��/#vj���6~j� D�1�jlZN`�/�w�E�#4�۠�����B^��,V�Sb����
_��wAr_:k�M�df��vwh��K������,�+i�O)����Bzow��hO��U��fս}�/�ݥ�Ҿ&��i����xB�KN�SwG,@����(4U\w4r
4h�u)�%S)w�,9�>��
֕-���f�Zk���v���ytZ{_;=PY�,�V�tk�R�ڮu:�$���6�ߩw�j��f� �dU���i�0	R;��O��+;��A��3�J���ӪW�q|YY�Zo/���ޒ������5n��fI�;��9��0e[Jj �����8_a�5GYs�b�FYOG1�`�EV�����? BPd;��H��^�)�G_�G�|t�l�����J�]CF?�7�.���W���J�:_�Z+����?��5��f��=p���J�p瑺�V�ril$� ��0��=���Dn	I�E2�U��hz��t+��a��Q�~h�O�`t�,]��p�!�d��3�O�V�{�(8��/1�Y�U��m�[����j�[*�:�0��a�|O�J�r\-�1�o�l���;�{��*��I���Ⓞ2.V�1X��%cK�8�#���'���>�-u���a&�qm��`,�;7���/?�V6����13T�A����P|'yU��.�븬w��@=�N擻Q<�9��U-_��O��r�`e�:N4o�1ܡ]"�O��lʷ�����1{���I�v-����t>����������O�$hZx���� q�c�(��.���/[[�՘�)\bl�|[S��#�#ax���:c�)���z-�0�beH���
?.���A��xK���*�^�'��Z�G�V��`Yy���-���l��1���gs��9�ٜ�,���'Z
6�?����Ϗ���}̳9���lu����s�Tsb�I{�~����s�_�\~ws��(���R=�H��=D���-�D��Y�C�e��2�4�!T�=]n'c�;�`Ф�����2��k�����\�Y�ǝ�ײлV�mZ�d����+����7�e|�+�gǗ��y�R�3��]�l�ɯ���D�O�3t�%�]���La�1��s��AOw���2bw��H�5I�� D��F<,62o���P��9,�=��'��Jz�j�7�'�M��[~�F�zzIPR�N���'Ӆ���v`/�ٰ�N��3j��ז�1��!�XV���μ�Ov7����(����Q��d�0����>%`*`�&\S��<Ce��_~��A#܃�����`�������Ons��8%(����K���ϫm�5�S�&�ǽ�M��c�x���r����W|���װ�ރ��?hdZ$����?�:���0�d(<�ѱ��S�z�4;#����aj#ܓC����!�@D�q�?S�8���M-'A�	�8���ZԲ�e����m'C<��l� ��C��� ��/�(4�V��/� ]�>�Ə��N[��aSxO���~�u�6�&�ᶿ��=���h��tA�e�^�`���!:l4�g�f�;�!���I�@B�����m�����?b1�������#�8��S�LsN����W��_G8"�/���JF�����]��w[�DX��\lsq�OeȔk���u��� ?`�ZyC��I'3;��3��#j;e�� Qt�D��oB'�$q�$/��W[��3�m"��N�p2l�7H�g�	M ߤ#'��Pc0l�yx�A*�!b��a7L�wbqyIfЄ8����½���1���5��֫�A�c�S�(7������
�:��H�]T.˖���'V�J��Nj�C����_8/g'ye�F쫘d�x���:#�&��8�1r��t�3]���i�N�d���k����>���XRl�����h�j��9~�_�߉|��2C5A��F��v��u������P�n�a\pE����?�y��v��s����N��͟KY_��_a�9i��T_<`ĺwk0Z%猅��챦z�s�iŗ�1�%��;t����+��д4GcK�G\�_J�B��8M�p-����+�T
t,iw�V)����ɼg��,3?\@ΗU�-�m)���A�e�ʓ�@��yLڐZ���x�� ��#�����)bK�}��K~a<�;d�L��^�v{��R�˥��{����{{�~>�c����J�J.�Vhf�@�{���4��)\��1L��(X��`�O��Y�����"��J�]m�w[�݃�3�|{�|�J�1<[]�#+�m�p�Z��$1^����K|�������_� ��3+X�"�'L~Opo����@�����#���#��Q��(K�K�r`*�I0�y��=� �v9ޥ�HV��Qͬ���������7���3$L}#�i�(wkZ\6y)u�K�
��rl�l�o�FԮ�����]����#qKl��;Zu�������������c��=��׀ ����3�`����^2�ԃܔ�eM����h[%�����ʦ3����=FYw�������ev�����Bf��(����n~��\��q	��O\��8wL*tB����%h�
�������~��$��M&�/�#	fZ��7D�m���
��t��v��[?��6��w�ZؓHD�X���Fս��:c�o;K#�KF�H7v˔%����O���uf��6��Fn�ɽ���,��}k���%�x`��(�"hm7L߷x|-�\!����Х+�#�����D7��=K�J����������qʏ�ҁ��9����2<}�+P5�p���|o�w��1�^��N�W��;�S[a�ͷ4�IY���ӭhr���+����<����������Q�y���x��ߢ��	[�܂�O>�9�y��0��1!݋�\x��ȓG�-A�Z�����t�9��<	clg�c��2Z���?�堨M�Ԃ������E�ǟ;��c�?{\rDvQ��G���B^��b���ߋ���MU�#١
�[�p[��赆���
ԅ�����~�E�+z�{������H#����Ƙ;��A����& �PL�w]�0>�w���EBQ��g��?Չ�E�ue�`�)ʡ�[�7R@�>s�2H��>GfNgP*|����Q��v������x�Ud
B�������`���]%<�K��
z�\��<�+��,[-ߨ�ЃȄ+X#A~��D�O]�08��0i�GI����<+��7L7�<	x "�o�ߏ��ի��p�ơ")~���U�%@`�fy���j�G<O7Cd��:	�L�*�o���ѯB�k�_YE��4g�g/��&|%�[�lWmL�"i� �vV��c�Id��t�~����+����ڤGX�ӝW2��i��윆}|�t�rSs���@Ae~����e�6� �m̷��!�?���,sS���8��!3Z�`y&��p2O�9��0������:!h"���Qڳ�Bd�p+N�ҭ7��Y���<���x�w��R�	�ǆME3�����V�$��t��zfp=�j#,%_��K�\(�c҅��H��!���J)�~}a���_y��H�M݌�C��5�_S�� �=`�wIU-f��P�e��e� �K�P�/a�g�t�1�ɏ�{�ozY�q	���m9�����;��v��X�n�%_�<�C��Y`�D��0B+
�%g�m0g���j#w��3k���}{��譄�%!O{+���.���my� ��������p��o=�Q�3K�:K��8C,9Sq���ٻ�Ǳ�<�;�[{fz�q�mviJ���LlǗx�H�['�'ΕF+�q'�s���5iF����7�!���� ��
���h� �έҕ�ꪞ8;����*���������_�������.ԗW�����6+���ݧ׋ﯢ#�p.i|}ԭ=��_q���}Q�N���Gv��i/7;���=�!��?��#)����udf�m{��=��\*��m�ז+/����:�j��pkGRF�������-�&vw��6Y�M#(�Hʂ�G�z���yV�h}�]�~��<&X�f}�P�L�&z_:l�m���+q���>�r-�x�Q�����زc�1��܏9����<��z���z����k�����.;�e�qr���G��} ��-�-��G��o��~��/��r&.��z�k�Rц�hF��ZӢE4j����c��U�"��bNQH���h-�����߽��������!�#����@���Q�u�U ������w�t'�?z�t?''���;BoB/}�ﺗ���m��ܸ/?�t�m��͂�69]�?�f�`���ϫ���O~����G2�]x�K���|��h$��{89��J��Ϩ?�����7M��7.������䷾��_��!�c|3�kG��}��-��E/�Hca��� #"�H]Wa��I���`d�A(��	��r�i��x���(�P�Z����TCo���?��������?��O�N������.�C�C��:xqk`��סo�~^���5������w^;��{�b>��=��{�?�_Z�@{QC�2�r�ei��.�-s�Z��B#+I%t|�*8G���7ۭLV�9��̽���:u���F����U�і7E��z�5��D���-�TP~�oH�1�Js[��ؒq�UU�e��2y��	q���䲸vE���"�D�_^��;=�R���jV�XM1Wqb�b]�wŽ����f�#�4T����sR��q�_��;E�RB�Z�0���H�9N�X�� ?�Z�<~~�X��JbU����M1r��5N6h�e!*m��!a�JΘN=�o���!_�G�ү�)d>��B��YCKѱLR.��v4籘4�#}g��s�m�7U�!��s�c�;"]��D�L���v8g�XY6.8��3�9�[�Ȗ1^0d#���>9�:��
�W�PM�N��Y(wg��n4{}�l�u.��2G;��V�5b**o�#0��>��1=��5�2O��+�˖V�	uR�F9:nG�I�F(��=H	=]����a>|AI�?��7Žޤ��E�q�.J�Y=��g�2iv��%������hu]T�G�&�IAyo�IAy�����侲#�����{�
.-(GSSFF��i^����f%Uj�#�k�RNI2	;�.I+WhT������i�"Y%�=��JyR��l��b�,n8���0i��������;��lw��LgPU�$#0��m'���:y]�Lf �1B4�$��Tu�[�ݠE��
2�S2X��ה��E�9���pӮ�HN���]*8Ej��Æ`����H�Y���=��"�yP.���
�3��I]*��j�3/��	�n{��D�/�(y�3;����'e�QLk��T��k�v���9}�b��΁g{nbz��PLT�mz�g{�gz�N�= �l?�µ���X۟r�1�c����82e�t��H��IVKJAkͬIL�R�ڮ����I���,	+�X5�Xu*[ h��t�.����?Ob~�j�n�X��`P^���tha��J����u�p"M��<������2�1�Б���2Ήٕ�A�3<2JF��
t9M�ΒmT��T�$
�Bf�eAnpj��h��I��������8~߀~�u	߀�����[G���yo+��� >����o�����j��b���f��;�~z��-���~�Fx�.��$�W{z܊�_�\7���t�u�o_��oxg�X}���^[E�z�'+���{���A�wo��[��RYz�RY]=���(:�(C��2��ē�2Qoh;6_U��͏qt~m�Y�l�לؒX8���.�`.p�,��s�\�:�y�����d�7V���2pYd
k�x仭P�'QJ
�0��2sj8D�q$���9�'df���`�d��e�XK��J�T�� R��J"dv�l�L55�f;5]���hZ��a�Q��;��a
�d��DPV�̒e��0�je�H��8ƨ���4Gg�� ���&�"�x�!�˨5~�1:l�t���I��x��2�t�Ub�n�D���N�G�!%h��i�6����-�k��,t:EV�2���WA0^��N��h�!�X�X=x(s$�dl��Yz�:��%��� Z��`&���Ez��7/�4�'�k�,W�aA(tdq�N��tfh�������=u�_am��grlN���H͵}�^�`eN�#"W�I-~&q�du�e�r�Y�[|z���u�������oѕ���/֮�����	�.�<��꣡Y�eGC���,Z���T�r�m�u)�K�\��y��a�ɥ�Q��u��:W}Y��v�d[�pU��|�/I"?<Ǆ�H;K��/�2+Ҵ�Zv��ʎХ�Rg*�]C�b�KL'����R��r}:Q3 ��B�`�Iq�T���d�I��8���Y=^-��D���=>�''I�D��Q�U�OLs9��0�`�x"�h�	S�I���3g��&�N��*��w�ɹ��i⿺�OH�gHf��D�&�g�Mr,"��7Ո��J��_C�u��ʐLck�h����qgaL�u�`��������ckc����ڠ�m��r��O��P�Rl/4$�|�Y<e�:<5��p�ǳC�QB���������Z4��Ha����
�n��X��xb��9�,�u
X[�s
YHW�~$��}{�:�ڎl$'ᄌ�Z::ոh���P�0�Ơ0h3m�b`I\�M�^/��B���4KO: �P\G����a2f!�2N~Z��j��1�s�ʇ9̚)ժV�����u��.����_���j��-]�2�Ҷt�l�nt�շ��J�+o����hN��"`<����	��Fsu{8zh���m��7�f��|y3�zz��}��!��Ç�7m�^ڞ��� n������+�*dE�2���M�@W�&]��ܧo��	u�4m��/[S��I{����u����N����x�E�w����+����z8��H�77鱾�/w�<���&x���@���+�'��+���|��KW9�%�?������W�IO6O���u����'����2��}�6�e�����ku�]oy�e��~��.=y��/M�k��ߌ�fn��f�san���vZCw�x�Ơ�=�Џx`�4
���i�}�8����(�N�0�^�CQ�Ƣ�7F=�o�z`��z`?�]x`�|��G�����Fڴ/��s}l���֟�	#$����5��OF����?�v/,f}���Q\��ߔ���k~_z�����/���g��D\ ��l�l�I��_Y,��2�J%��
�K�Ӓ1=i��l'rt3�jLl�6�U��b,G5�]�[�!�T�=٣�Mg$=4�)L%z��*G��t�k����k����[Tľ���۩���D����T�`�^0U���������]����}�7�o`N��� ���E���Ƞ��^���-k�l;�B<�J�"	��aG�ġ,0,8�4��a�l׈;����p)�R�dY+���<��mt�t�$Kӹ���)��yLe�м�uX�����ۅ���gx���B1��M�m��B�;V2����
�Y�K(������m�q����뇃k���BW:Ɠ�1�]���>�sSy�=�?�LF���������'��ɟ�������A��'|��Y2���8���?9�c0������.�������eɜ��0���?���?������+�����?������8��}�O��To�`0:�'���w�����O0���k�v��w�����I��9Ǿ��������A�� H�����=I�>�{���A�?��������^J�`�_��������s��{�a����``O8�Fv�?�����A�g:���g��C��'�@��~꿑5� �������A�?����H���������`��q�?yN�?������RPm)��t�jK~�ܧ����������4��}E��?��� �?��}Á�0�'����}C���A����A�?���O�S����p�����������dg�?N�������@D�kQ���^�����cZC�7"Q\�ɨ�h�55Ju���S0!`���zu?�8�������~pA��'.�B�N����f
[��D�x��BIJ�P�I���hgDvU�E�FFB�Y�R�!�_��UC�f0���ד<	95��-�&���Gb3�)۽~�6�lc&�2
Ն�^�||�g��;�C��A�O����YA��p�?����!����?�����뺁~߅g���������Ǩ���Ǳ\-��2r(M��0�J�%ǣXklT�k�/�ۙ��Qڝ�6���~��A�JG�c�ǰ8�"�ؤ?&�DD�S�B=�21�5���~+Y��:ڎ�p���P�����0�$��	~�M}W|o��b�W���o��
��
��
��
�����O�}�A�?���8�}������9��b���Us�Pь�L�4>w�/Vy�������k�NT��_q�c���p@QAQ��rF��wQP�_�iLz���N�w�����s̬9��ZKת��d��с���f�z�M�-U�7��+д�ꎳ�~Z�n��OZ�zX�d�=J�(��RJG�\�$�E�m��ݠQ���K4I8䢽.���-���k[[�o������*���ɓ��z��6�;-6���Oe
�H�\�v����{�"+���u�fۨ��,�A��Z�Q�4�u�|Uuf��z>;��n�0�T�C��Hh)�ix\����7���8�3�BYU�TJ�|�^^��κ����V����Q�V`ҨU;"�����5>���9����r���	���������&�����h�g����$�� N�����l���!��0��?��G��X����?��/L���Ür��k�?��e��?B�0�?�y D������!������/�!����g��0�\��������_0�?�y D������� �?�����uA��c��U>{�~8B�����_!��������c6�����?�	����h�g����?������/��?������p��ʐB��_8��w�?!��	��?��\�����EB���������X����&���Y�!�����D� �E� ����l����?.����q�=������W�?����Q�fjo�6�~݉{�����5���?����=�sV�e��^�T���z��[�|H�U�p���u�ӆl�((�Ҧ^w�V׶��aWs_�aZ��찑��������2T�5N�[�J7�+����������Z�O5 �\�;�>h,KS�HT��ԃ��'���uj���)[�VS�v��KRe�]�^�Bf&�d��Ay��l�bɏ�����t�e���A��c���,(\�As�B��k�?"��0��_X@�CsH� ��?��΂�������#������!�����������$����A������ ���#��� B�1��.��ExJ��.�_��m�G�s̃���?�����K�(Q�����H�}����X���P`��FEB��*��ND����z��� ��9���C�?����տآ�m��o���Pm�6����ڼr�ܬT�?΍�f�9���nܓ�RwƯe�9'ҙ����8���;�t8��Ѣ�2�4�����ީt��r���d��];ɹ��ǋ�2��O��C�9&u�,��������h�ɠV�C#�v����Omz�fÿ��݋*�����Y
]��%���Ł�����p���ֿ.6��K�%A���+���%��r0�W��Y�����暳�:ͬ�h�,s�/�O�VN���m�$It��ܯ�e��3��@����5����_c{���Y��\s��ìe����N��ܤ�i�/�hx\�,����]�A�a�ǁ��� ����+�{��������/����/���W��h�b@���_AxO���/������ �C;*�%z>ȼ-���u������?��z)x]PZ��-1�"�*3))գ<u�����bZ���\�B-�\0�Rv��pכ��V��x�Y@�F��u���㒳mi�yE[���y�U�iH�k��Ӟ^���G��z55��	���zU-�+o�R��B��^��r�5Y6י��eê��#݊6\�UQ0��F�T����r�+6V��Y���e0��#���k��"�fp��2�����k���AE���t=묧�����D�h�[q��lR|Ez�4P��T<0������ߨ�cw��Í������*����9���H���tW�!Ұ��������q�������ŉ���������_0��A�����H� e���Hf��o ^>�0�|_@��L_�\t�Df��py��
�>8��{��>�wyD���2�W����dB�*�ڱݣ��1
��ґ�;Z�[���G��f����.[����Y���	�?�h���/,�l���E^������?Os4��� 	��
w��"��� ���k�C���"%�]��@�h��Y1���q�/B@�� ��	X��	�������,���O�H����՞�K����d7���-�����ۂM��X���}\�uZ�����5���GA��O3P�U��0ًT�Z�?Z�ŉ��� �A��}�����I���������,����������wE^?s�9�����A��c�;�����������C�~����q���E�H��������?����l��P(���������/0�
�����/���?�����
�����/ŗ�?���/��� �cA����~bb�\�������/��C�����JEW/�/W����,{�lYWj��ν\��$s���vӜ���R�������ٗ_t�8U4���Ƈ`%$��1�5��;ڎ�V��1>Q��0GCg���o�ڮ���vWx�
lm���]T��'�x��k��f0?��^7����y5΁����w= _�����S����4�|�+�Z�,#�4]^,Ғun�O�j��N��rj��,�mGI�`Ι3�<=Y��0S���;��J����U��e��!4;�xy�0ENdW�\���_�k�KS��,se��Sī~�>�:2)�z�D}	��nO�r�� �&�PoX��([n�Ԉklf�{�mWԸ.��/\k�95G�E4M���ԡ޹�Ȏjŕ�n^^z�L!#�3��K�\�5=qW���N}tn4�q�2���Dtt����kY=$��k�Ůa%aϠ�Ȗ�i������C����Y���� ��k�?"�������������� ��?ϊ������=�o^��j���o��N�4)k�i3�fc�t�꿂��2{����0����}�T���5]E���=�u�Ts���ym8v/ȝ���=�n�,vp}l����5�k�u/�g�2����W[��ѷm�<\Lv���x�BS�T}�Җ��{�q�\�\�=��i$g85s!�)5���Zm�\�Ҳ�E#�PU4��f�-��q��ӕ�Ԟ�;�7Nf�7潞ִUޤ�ʵn�������ǫ:WU�:���<+wv��Z�j7F{I�4��u�����&�nX���ѕ�h�غP�������z**�c�6���V���Tň�~o�2:+�@)O�㒤[B�]���*�rl�]�!nVN�4�T7F�+�iߥ�}��F��T��0q�����v���̃�o�����Ss � (�����#����������[�� ����>8���oX�������ҷ��0�1E���q���SY�����B���6�G{pm�B]C �&@=5���~:@��� �i�"u�i3~�i�� �N�s[ܯ�)���Qc��1�p�Lz^0?-Uk�j�b�Oؔ��uu���������q'_N��pǰ�$ߠHp��s �K�#9 i�Q�REUxQ�g8��ŦK��B���3�4�Ĝ��ۻ�C�r M�v��C퍪"�̊b!o������h+���eu�K6%��/�ڂ����Do�vA��Б��EUVY\����a @�������_[�����Y� � ����q��8��������+����O����)�6�� ����	�Ͻy/<����$�?�\ĠO���Gt �-G�F�ˁ³\�1�(Op< F���3B
�yA�)q	��h�7�<����h�ʛM��������qK��]f:�`�<,�z�;w���uv�J�zN'��Ź�*R���W���1�����'���_c�Y\���f��ؐE�Zֽ����zt�
5{��+0��GA���?�C����C�BA����8�����0�������}1� H����W��v��±��zy��n$TVjFa�6oO���U�}�Njb�ѳ�녋���.�s�o�z�n7�&��^w�ᔦ�}��8<2Ǫ�-{����:�y:J���mom���ؤ�4װ��v=oO���� c�ga�� ���`�'^��$俠��8@��A�����b�@"������?���{�������������U�����t~���=������j�w�vWi�kcml2��x�����%Mo�HzA���V仵Q��t�ᩉ�o3��N�N�q`�f<�N�A'n�Źz>g�6�R�9͚���g���!'��MN�k�A�|��=��n]��w�����彰�b��]�:u��Ի�-��r�C�<�5ݗ�s����y[�L9��m��5��b�@��bդ��mݞ�X�}n&O��}jul�Qw�WJfs1n�3��'�V�hc1�x��JEe7qR
�p���h�����?�V��������3|��#^I������ ��C�����������J*�������� �]��?4w%�����_y���0����W��Z����p��	x��x!�����#��Y���A���0�(����y��c��!��������y�F��
��_[�������v��/D���h��� ������[[���?���A������O.p�����������������_,���p�O,p��G��� ����C��P�'ܝ���WL������|ߧy��&h°!�HA�"��-�r�!B���8���J�K!�D�`�O	������$���r�ø��g+��j:0�{W�ݦ����S�8�NҎ$���� �X;�l���f)�EH~���SȖl9v�bI���Q��{u�-�����V��OOZwC�>�j�V7��?�t���κ׻��MˬUƤwW-,�}�0�����}�&)~�m�G�a�d���y5'x��`@#�+��r�n��y9���[����������C�����#^8Q:���L�?~��0t
�O��|�=^�=
��m�I���x��iR��/�������7�O?��c�� t(�*Ey�*$��/(i�t�T$5���"��|!-�\�,�9��g�<]���4M�r��>t
�������0�+���z~���nZ� �U��a_�KU�c7]�R^;ӹq`g5\��?��j��r��K�<��՛e�d �p�1�֝��0Ч�U�nF��Y�3�n��n��6�Q���עnr�E�(�����)��q��x��������O�1�?���q��t
�O�{����A����|����cS��1�������������!�L1���t�O�Y���?�����G��c�?:�g��b�?�������?z�C&���������������9�1���A��?G��oC�b�����N�C������ǃ�I���Lq����}��б�z��}��K��?�+���o\F�Q�z��;�������ί���}�ѶN<�����=���T��9#Q��d��*pFS����0��J̖}�����Ƌ�?���}�Qck����yW�T�}��҂�{SȵZM�	�{b׿�L�����	�5Ư�����~�bv�xb�ǿՍ�!�B�6a�NU�)��)����,G��dA�f2k��m��a[�J���=Fg��U&�{�b�f�a�7.�k>1w�Z�[��Ek��[7�����N��K���������>~����(��o��$�?�'��� tZ��uh:���O*��A��O��O��O��O���G���>~����(��o��$�?���F�����߱�8:�?^�?����������/0-�m[�k%�V��u^����}���=� ��,��'Mn8l��{F�h���Z�b̑w�#~U�2���/�=����[���*�*}�:�`��Jq=����d"]�θ��J���1����TkB4�{3�Չ�j�e�5�Q�~�l�k��M�4r�F����c?� 6���P�c���Gݑ���,�?J���Ȑ5��x�����+�U��Z�e�u���GӬ�+M��пb�fc6�a�ވu�^���g��q~��K�V/_s�JGȍi~]�����gM��؇/�k�xl�Z�i���d��3S�irN������ՙ;�Ǣ�gkl����̯����kb�m�\9�ԩ�l�E��X�BC�1��4�W�r�S��������}1;*�&��<_�ea��aq�))������5o]��l�����b����f�#��������L����$����?��?�N������Z6���#P������)��,����A��_Q�t^V�iE&si%[�Jt!Kf�E	���
R^����C1����$�9'g3ŌDB2�F���)�����c��0�+��w���t��V'UN�r�c9��}_\-�L�<����r��N�*\t��PPz�&K��x����kn᥹E���4���z��.eӚ��'9v��9��J�F�쬡�H����*�g
���T����J�0�����<��F��{T:��?���G'����G�����$r���!�������W�^����:�4GZ^��XPs̢��6/���x*g{б����72�6?�NJϋ����*.ZW1s�����e�[�ir����dZK�4��׆�VU������ȝQ�g�:��K�l����Nc�������YL���b��3�)����:�����_���x�W������b�t�_>����3��wz���#�O�=����h��1"����ƪ��u~u���ez����e���Y[�?���� b۞ݻ ��reh�Sf��J�M ��`�Kբ�A�I�7\+S��LjF�ƶJt��)�~��es�땄
w/S�ZK6��k�W���֕(�ln���z���b�5�Sm,��6���FZ�|��^��ʬ�d�?`�_f��I0�7lhS"SMiZ�*�![�
�{׾�����j�B뺝鵝=�;MNO �v'M��+��1��������:��|���4�.W�u�n{�r��xW�2{~sS���~��j��r��ݐ^8�v���),�`�j��\&���jV�{�|mŶҩ�zֿ�ߩ�i4���?��ƫe����<M��?�����A g-ֶ�M\Pc���^$c@�i` J��@| �N�:��eh:0QS�����,DyT�D�P�į#���m+�L�$@	���c�X*��0MQ�M%� �R�󋫴U��_��
x�	���b� J�\���e�鿺l�񬷀r0�=A'4  A��j� C�]а����jT�"��;�j9�tN$;�^�7�}�c�]DxS���_-�����ܧn�{������s����p��kh��Q2Dz�0tYw��l��ɯt�-ώ���gr���� a�|��/�,��u��¯�6�">A���hѶ�5.'�z��ěGs�c����J(��[ M��ۇ'�g�y��/�?	�_��Y�GD��������á>��P6>���/A]�>�F�C��؃�yl]�z�~�k���k��g�_���w_���w��?�����DW�$�v�]&�DG}lI.ʋ�G}�5P��yP���h��8!���
l�,��-��N��ho����W-���pP�58C)��Eg[M�q��������(�fp����� �*wK-�[.%�go�$�~!����e���/ȴ�|'�hU��4V��e�J܉��]�6D�RP��y��c1O|Ё�s-1,k���3��t���Y�����<�M�7bwcyh�[?�%����%4�3!�<��kp�.�*uS�+𹇯�D�f>���G���ɵ=��cU���/�lYH��kT��cL�s��p� P��AZ��bӎ��!�,w� �	8��E�+C�[����x��#�}������~A�e�0t�}'���`����K�ݸ�/@�!�Qe�ul��o����o�P�HL�O�x�{?]����#�xn�,�{�E���(���b���y��}2@�8�?��O,ߵ$O7���z[����������ec�� �s4h�?�1%���erO��@��e��̰B���ʕ�ӯ^~�JD��]av��m�:�W�Hr"���AF!HX���\ְ�H>�WB�'%|����h��ذ�����m�r��$l~�J`s;J9~0������a�=^'�>���?}����d���q45]�O�'��"��0�C��N-�\�Ф>Y/�m@ECB��,^|d���92I����m���c�e�m���/SЕS{�E2���/y�j1�Ş����ėk�7�Y�|�T��T�o~���Q�ds%�R6_�����LV��TY�jZɫiQ����H)�*�ŜH�(R9�֙A�a��
n���,}���3 �8������v5��$nj �on����y����X����ˊ�$�t��+��� -�bQ�\�.�<Y�`F�|���A=Y(B:�bN��c@B�q��߅ʧ�7�����Vw%|�[SomM4&��}����e����5���{2����oS۶P�$���L�Ѯ4�!߸T��i/g���|�)��׻$��/����j�&߯�K�XB^˺_�6��K��ˍ�F�ש�.#�]���T�Wnu0�0�-{�|�[E�/@�Z�)�Z��$��rJCN�'��|�v��ڊ�?Qt��$�sr�`���\L7ݵ�mW��5�-%ؖ�(���#�������P��_�/���"�����;�x,�ZY�</<��>Wej-�]z��D�g�ݬ��-�*uڵV��3��E*��q��R�S�gF�U�ٖ��I\�-���4x7�F�^�M$�gu+��:z�����v�\�ܶ���-ԛ�u�5��v�w�Q-��7��Pj�=p�I����<_��g{}�χKL�a���\yRb���k�j���]m:HƏ+�E�X���>��<̣8%�r9t�R�����AB��yI���bW������3~���d���`c?���
\@Sqn���Н/͔�^$�6ұ���}n6,�"Γ���(�{����*�uQw��&x���Rs��O���?�ƾ��s�h+�o���Ig�e���3�N?y���d���������R�n�$љ��6�^3��ێ�m[�W��u��al��Ix�$��t��W	䉎y6$��_��"Ӊ�?0�-JA�[�l/o"�E�-{�$��t��3���Aw�'�>�� �z�k��;�?����3𗿀���_�mo�!VH0ޥ`}���ug����p�������v�`����9@B��`����2oʌ���kù�5Ƴ��6�T�_*�P� �V��04����&)h�a7��p��I�u��`���V4D/�~Atm�u����M�� q�3��<{ӥ���9���2��OMo�ǵ?���^�������NQ8)���	��a&�`){��(=T�Xd#�����9�Y�=�q��a����`q�3,`r�|3����\>Z�C���x�/C��?B�����U�W\]�{���@�y�����y��������j��{�?�/Bm4���剅�)O�<>�m�g�^ �����- Z� [��4��3A]��:��RHOR�g��&��D�$�����#����\�����>���;��juH�U�Sϲ��W����=���h]ۺQ��}Z�ǃ��M���#����o��~����{�
���uK��I�@<00	�� \�-aI��$T���v�$M��c���M��َ�>����f�ᇢ��&�ld�0=y��I�l3P4:T&�書SU���];e�u�L���Xf��	R���
�*;�*��s��Վ/��]^�a/��2I��s�}1�9k3U�P��k�Ə��%l�w.�L��%�5�,��N�TVv�o�l��~�2��ڶʯ���Y��V���?�XY:�RV���w�@��Y������E��oEu����ǋ򵎙s�s�=�d��{��m ��(Q���x��l�3Ǳ�уGe/v}��Z�J������/��U�`4qezn8	�j"�Q(������� Wz�+E?�p��
�?�D�E4��_��Qm\��6����ތ���~�q��kݴ���I���pɶW3Ƌ����z��<<�I8�hnn�C�a�kY�t�l����3��NM�ԥC�(�Y.�I �c7��fG{$��nÂE�JIo-	��l5�M�1�P���@_������� ��g������ �����a��D�N�5�Ǿ�<���1���t�P�8�F��$��.����L6�X l���(ʼ4��]ki�5�Wa@��ZC��d��P���.�(�Q�1º`ů>\n���)N�-��p<ye�q�y�ʵL̏��si�q<�@ �@ �@ �@������� 0 