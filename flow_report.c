


#include <netdb.h>
#include <inttypes.h>
#include <lt_inttypes.h>
#include <stdio.h>
#include <stdlib.h>
#include "libtrace.h"
#include "tracereport.h"
#include "contain.h"
#include "report.h"
#include <stdbool.h>
#include <time.h>
#include <string.h>

static uint64_t flow_count=0;
static uint64_t qsya00 = 0;
static uint64_t qsya01 = 0;
static uint64_t qsya10 = 0;
static uint64_t qsya11 = 0;
static uint64_t flows = 0;
static uint32_t a[131072];
static uint32_t flow_usec[131072];
static double ts_now;
static double ts_last;
static bool flag = 1;
static bool init = 1;
static uint32_t i = 0;
static uint32_t j = 0;
static uint32_t k = 0;
static uint32_t num_pkt = 0;
static double delta_time = 0.002000;//1000us


static uint64_t sum = 0;


struct fivetuple_t {
	uint32_t ipa;
	uint32_t ipb;
	uint16_t porta;
	uint16_t portb;
	uint8_t prot;
};

static int fivetuplecmp(struct fivetuple_t a, struct fivetuple_t b)
{
	if (a.porta != b.porta) return a.porta-b.porta;
	if (a.portb != b.portb) return a.portb-b.portb;
	if (a.ipa != b.ipa) return a.ipa-b.ipa;
	if (a.ipb != b.ipb) return a.ipb-b.ipb;
	return a.prot - b.prot;
}

static int flowset_cmp(const splay *a, const splay *b);
SET_CREATE(flowset,struct fivetuple_t,fivetuplecmp)

void flow_per_packet(struct libtrace_packet_t *packet)
{
	struct libtrace_ip *ip = trace_get_ip(packet);
	struct fivetuple_t ft;

	//printf("%d\n",packet->wire_length);
	if (!ip)
		return;
	if (k >100)//stop more than 100 results.
		return;
	if (flag){
		for(i=0 ; i <131072; i++){
			a[i] = 0;
			flow_usec[i] = 0;
		}
		flag = 0;
	}

	ts_now = trace_get_seconds(packet);

	if(init){
		ts_last = ts_now;
		init = 0;
	}

	if(ts_now - ts_last < delta_time){
		ft.ipb=ip->ip_dst.s_addr;
		a[ft.ipb>>20]++;
	} else {
		sum = 0;
		for(j = 0; j < 131072; j++){
			if(a[j]> 0){
				a[j] = 0;
				sum++;
			}
		}
		//printf("%d %d\n", k++, sum);
		//printf("%d : ts_now = %f \n",num_pkt++, ts_now);
		ts_last = ts_now;
	}



	
	ft.ipa=ip->ip_src.s_addr;
	ft.ipb=ip->ip_dst.s_addr;
	//ft.ipb = (ft.ipb >> 16) & 0x3;
	//printf("%d\n",ft.ipb);
	ft.porta=trace_get_source_port(packet);
	ft.portb=trace_get_destination_port(packet);
	flows = ft.ipa + ft.ipb + ft.porta + ft.portb;
	printf("%lf\t%x\t%x\t%x\t%x\t%d\t\n",ts_now,ft.ipa,ft.ipb,ft.porta,ft.portb,packet->wire_length);
	flows %= 256;
	flow_usec[flows]++;
	// ft.prot = 0;

	// if (!SET_CONTAINS(flowset,ft)) {
	// 	SET_INSERT(flowset,ft);
	// 	flow_count++;
	// }
	////ft.ipb=ip->ip_dst.s_addr;
	// sum = (ft.ipb & 0x30000) >> 16;
	// sum = (ft.ipb & 0x3) >> 0;
	// if (sum == 0){
	// 	qsya00++;
	// }else if (sum == 1){
	// 	qsya01++;
	// }else if (sum == 2){
	// 	qsya10++;
	// }else{
	// 	qsya11++;
	// }
	////a[ft.ipb>>24]++;

}

void flow_report(void)
{
	FILE *out = fopen("flows.rpt", "a");
	if (!out) {
		perror("fopen");
		return;
	}
	float sum1;
	// sum1 = qsya00+qsya01+qsya10+qsya11;

	// fprintf(out, "a0: %" PRIu64 " %0.3f %0.3f\n",qsya00,qsya00*1.0/sum1,0.25-qsya00*1.0/sum1);
	// fprintf(out, "a1: %" PRIu64 " %0.3f %0.3f\n",qsya01,qsya01*1.0/sum1,0.25-qsya01*1.0/sum1);
	// fprintf(out, "a2: %" PRIu64 " %0.3f %0.3f\n",qsya10,qsya10*1.0/sum1,0.25-qsya10*1.0/sum1);
	// fprintf(out, "a3: %" PRIu64 " %0.3f %0.3f\n\n",qsya11,qsya11*1.0/sum1,0.25-qsya11*1.0/sum1);
	for(i = 0; i < 131072 ; i++){
		if(flow_usec[i]>0){

			fprintf(out, "%" PRIu64 "\n",flow_usec[i]);
		}
	}
	fclose(out);
}
