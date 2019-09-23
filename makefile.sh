#!/bin/sh

echo "Filtering data..."
# filtering cloudfront form AdGuardSDNSFilter
curl -s https://adguardteam.github.io/AdGuardSDNSFilter/Filters/filter.txt | cat | grep -v '!' | grep "cloudfront.net" | sed 's/||//' | sed 's/\^//' | awk '{print "0.0.0.0 "$1}' > tmp/adguard.tmp
cat tmp/title-cloudfront.txt tmp/adguard.tmp > tmp/cloudfront-hosts.tmp
cat tmp/cloudfront-hosts.tmp | grep -v '#' | grep "0.0.0.0" | awk '{print $2}' >> tmp/cloudfront-rule.tmp

echo "Making titles..."
# make time stamp & count blocked
TIME_STAMP=`date +'%d %b %Y %H:%M'`
DOMAIN=$(printf "%'.f\n" $(cat source/list-hosts-group.txt source/list-hosts-group-VN.txt source/list-hosts-VN.txt source/list-hosts.txt tmp/cloudfront-hosts.tmp | grep "0.0.0.0" | wc -l))
DOMAIN_VN=$(printf "%'.f\n" $(cat source/list-hosts-group-VN.txt source/list-hosts-VN.txt | grep "0.0.0.0" | wc -l))
RULE=$(printf "%'.f\n" $(cat source/list-adservers.txt source/list-adservers-all.txt tmp/cloudfront-rule.tmp | grep -v '!' | wc -l))
RULE_VN=$(printf "%'.f\n" $(cat source/list-adservers.txt | grep -v '!' | wc -l))

# update titles
sed -e "s/_time_stamp_/$TIME_STAMP/g" -e "s/_rule_vn_/$RULE_VN/g" tmp/title-adserver.txt > tmp/title-adserver.tmp
sed -e "s/_time_stamp_/$TIME_STAMP/g" -e "s/_rule_/$RULE/g" tmp/title-adserver-all.txt > tmp/title-adserver-all.tmp
sed -e "s/_time_stamp_/$TIME_STAMP/g" -e "s/_domain_/$DOMAIN/g" tmp/title-hosts.txt > tmp/title-hosts.tmp
sed -e "s/_time_stamp_/$TIME_STAMP/g" -e "s/_domain_/$DOMAIN/g" tmp/title-hosts-iOS.txt > tmp/title-hosts-iOS.tmp
sed -e "s/_time_stamp_/$TIME_STAMP/g" -e "s/_domain_vn_/$DOMAIN_VN/g" tmp/title-hosts-VN.txt > tmp/title-hosts-VN.tmp

echo "Creating hosts file..."
# create hosts files
cat tmp/title-hosts.tmp source/list-hosts-group.txt source/list-hosts-group-VN.txt source/list-hosts-VN.txt source/list-hosts.txt tmp/cloudfront-hosts.tmp > hosts
cat tmp/title-hosts-VN.tmp source/list-hosts-group-VN.txt source/list-hosts-VN.txt > option/hosts-VN

# create hosts-iOS file
cat hosts | grep -v '#' | grep -v -e '^[[:space:]]*$' | awk '{print "0 "$2}' >> tmp/hosts-iOS.tmp
cat tmp/title-hosts-iOS.tmp tmp/hosts-iOS.tmp > option/hosts-iOS

# create domain file
cat hosts | grep -v '#' | grep -v -e '^[[:space:]]*$' | awk '{print $2}' >> tmp/domain.txt
mv tmp/domain.txt option/

echo "Creating temp file..."
# create adserver files
cat source/list-adservers.txt | grep -v '!' | awk '{print $1}' >> tmp/list-adservers.tmp
cat source/list-adservers-all.txt tmp/cloudfront-rule.tmp | grep -v '!' |awk '{print $1}' >> tmp/list-adservers-all.tmp

# create rule & config files
cat tmp/list-adservers.tmp | awk '{print "||"$1"^"}' >> tmp/adservers-rule.tmp
cat tmp/list-adservers.tmp tmp/list-adservers-all.tmp | awk '{print "||"$1"^"}' >> tmp/adservers-all-rule.tmp
cat tmp/list-adservers.tmp tmp/list-adservers-all.tmp | awk '{print "*"$1" = 0.0.0.0"}' >> tmp/adservers-config.tmp

echo "Adding to file..."
# add to files
cat tmp/title-adserver.tmp tmp/adservers-rule.tmp > filters/adservers.txt
cat tmp/title-adserver-all.tmp tmp/adservers-all-rule.tmp > filters/adservers-all.txt
cat tmp/title-adserver-all.tmp tmp/list-adservers.tmp tmp/list-adservers-all.tmp > filters/domain-adservers-all.txt
cat tmp/title-config-surge.txt tmp/adservers-config.tmp > option/hostsVN.conf
cat tmp/title-config-quantumult.txt tmp/adservers-config.tmp > option/hostsVN-quantumult.conf

# remove tmp file
rm -rf tmp/*.tmp

# check duplicate
echo "Checking duplicate..."
sort option/domain.txt | uniq -d
sort filters/adservers-all.txt | uniq -d
read -p "Completed! Press enter to close"