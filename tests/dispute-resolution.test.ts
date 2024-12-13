import { describe, it, expect, beforeEach, vi } from 'vitest';

// Mock contract state
const contractState = {
  disputes: new Map(),
  nonce: 0,
};

// Mock contract call function
const mockContractCall = vi.fn((functionName: string, args: any[], sender: string) => {
  if (functionName === 'create-dispute') {
    const [projectId, client, freelancer] = args;
    const disputeId = contractState.nonce++;
    contractState.disputes.set(disputeId, {
      projectId,
      client,
      freelancer,
      arbitrator: null,
      status: 'open',
      resolution: null,
    });
    return { success: true, value: disputeId };
  }
  if (functionName === 'assign-arbitrator') {
    const [disputeId, arbitrator] = args;
    const dispute = contractState.disputes.get(disputeId);
    if (dispute && dispute.status === 'open') {
      dispute.arbitrator = arbitrator;
      dispute.status = 'arbitration';
      return { success: true };
    }
    return { success: false, error: 'Dispute not found or not open' };
  }
  if (functionName === 'resolve-dispute') {
    const [disputeId, resolution] = args;
    const dispute = contractState.disputes.get(disputeId);
    if (dispute && dispute.status === 'arbitration' && dispute.arbitrator === sender) {
      dispute.status = 'resolved';
      dispute.resolution = resolution;
      return { success: true };
    }
    return { success: false, error: 'Unauthorized or invalid dispute state' };
  }
  if (functionName === 'get-dispute') {
    const [disputeId] = args;
    const dispute = contractState.disputes.get(disputeId);
    return dispute ? { success: true, value: dispute } : { success: false, error: 'Not found' };
  }
  return { success: false, error: 'Function not found' };
});

describe('Dispute Resolution Contract', () => {
  const contractOwner = 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM';
  const client = 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG';
  const freelancer = 'ST3AM1A56AK2C1XAFJ4115ZSV26EB49BVQ10MGCS0';
  const arbitrator = 'ST3PF13W7Z0RRM42A8VZRVFQ75SV1K26RXEP8YGKJ';
  
  beforeEach(() => {
    contractState.disputes.clear();
    contractState.nonce = 0;
    mockContractCall.mockClear();
  });
  
  it('should create a dispute', () => {
    const result = mockContractCall('create-dispute', [1, client, freelancer], client);
    expect(result).toEqual({ success: true, value: 0 });
    expect(contractState.disputes.get(0)).toBeDefined();
  });
  
  it('should assign an arbitrator', () => {
    mockContractCall('create-dispute', [1, client, freelancer], client);
    const result = mockContractCall('assign-arbitrator', [0, arbitrator], contractOwner);
    expect(result).toEqual({ success: true });
    const dispute = contractState.disputes.get(0);
    expect(dispute?.arbitrator).toBe(arbitrator);
    expect(dispute?.status).toBe('arbitration');
  });
  
  it('should resolve a dispute', () => {
    mockContractCall('create-dispute', [1, client, freelancer], client);
    mockContractCall('assign-arbitrator', [0, arbitrator], contractOwner);
    const result = mockContractCall('resolve-dispute', [0, 'Resolution details'], arbitrator);
    expect(result).toEqual({ success: true });
    const dispute = contractState.disputes.get(0);
    expect(dispute?.status).toBe('resolved');
    expect(dispute?.resolution).toBe('Resolution details');
  });
  
  it('should get dispute details', () => {
    mockContractCall('create-dispute', [1, client, freelancer], client);
    const result = mockContractCall('get-dispute', [0], client);
    expect(result).toEqual({
      success: true,
      value: {
        projectId: 1,
        client,
        freelancer,
        arbitrator: null,
        status: 'open',
        resolution: null,
      },
    });
  });
  
  it('should not allow unauthorized dispute resolution', () => {
    mockContractCall('create-dispute', [1, client, freelancer], client);
    mockContractCall('assign-arbitrator', [0, arbitrator], contractOwner);
    const result = mockContractCall('resolve-dispute', [0, 'Unauthorized resolution'], client);
    expect(result).toEqual({ success: false, error: 'Unauthorized or invalid dispute state' });
  });
});

