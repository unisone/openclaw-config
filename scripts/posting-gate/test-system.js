#!/usr/bin/env node

/**
 * Test suite for AI Agent Posting Approval Gate
 * Validates all components work correctly
 */

const fs = require('fs');
const path = require('path');
const axios = require('axios');
const { spawn } = require('child_process');

const APPROVAL_SERVER_URL = 'http://localhost:18790';
const CONFIG_PATHS = [
  path.join(process.env.HOME, '.openclaw', 'openclaw.json'),
  path.join(process.env.HOME, '.clawdbot', 'clawdbot.json'),
  path.join(process.env.HOME, '.clawdbot', 'moltbot.json'),
];

function resolveConfigPath() {
  const fs = require('fs');
  for (const p of CONFIG_PATHS) {
    if (fs.existsSync(p)) return p;
  }
  return CONFIG_PATHS[0];
}

const CONFIG_PATH = resolveConfigPath();

class SystemTester {
  constructor() {
    this.testResults = [];
    this.serverProcess = null;
  }

  async runAllTests() {
    console.log('🧪 Running AI Agent Posting Approval Gate Tests\n');
    
    try {
      // Test configuration
      await this.testConfigInstallation();
      
      // Test approval server
      await this.testApprovalServer();
      
      // Test message tool integration
      await this.testMessageTool();
      
      // Test approval workflow
      await this.testApprovalWorkflow();
      
      this.printResults();
      
    } catch (error) {
      console.error('❌ Test suite failed:', error.message);
      process.exit(1);
    } finally {
      if (this.serverProcess) {
        this.serverProcess.kill();
      }
    }
  }

  async testConfigInstallation() {
    console.log('📋 Testing configuration installation...');
    
    try {
      // Check if config file exists
      if (!fs.existsSync(CONFIG_PATH)) {
        this.addResult('Config File', false, `OpenClaw config not found (looked for: ${CONFIG_PATHS.join(', ')})`);
        return;
      }
      
      const configData = fs.readFileSync(CONFIG_PATH, 'utf8');
      const config = JSON.parse(configData);
      
      // Check posting restrictions
      const postingConfig = config.tools?.posting;
      if (!postingConfig?.enabled) {
        this.addResult('Posting Restrictions', false, 'Posting restrictions not enabled in config');
        return;
      }
      
      // Check tool restrictions
      const tools = config.agents?.defaults?.memory?.trim?.tools;
      const messageBlocked = tools?.deny?.includes('message');
      const approvedMessageAllowed = tools?.allow?.includes('message_approved');
      
      if (!messageBlocked) {
        this.addResult('Message Tool Block', false, 'Standard message tool not blocked');
        return;
      }
      
      if (!approvedMessageAllowed) {
        this.addResult('Approved Message Tool', false, 'Approved message tool not allowed');
        return;
      }
      
      this.addResult('Config Installation', true, 'All restrictions properly configured');
      
    } catch (error) {
      this.addResult('Config Installation', false, error.message);
    }
  }

  async testApprovalServer() {
    console.log('🤖 Testing approval server...');
    
    try {
      // Check if server is running
      const healthResponse = await axios.get(`${APPROVAL_SERVER_URL}/health`, { timeout: 5000 });
      
      if (healthResponse.status === 200) {
        this.addResult('Approval Server', true, `Server running on port ${APPROVAL_SERVER_URL.split(':').pop()}`);
      } else {
        this.addResult('Approval Server', false, 'Server responded with non-200 status');
      }
      
    } catch (error) {
      if (error.code === 'ECONNREFUSED') {
        // Try to start server for testing
        console.log('   Starting approval server for testing...');
        await this.startApprovalServer();
        
        // Wait a moment for startup
        await new Promise(resolve => setTimeout(resolve, 3000));
        
        try {
          const retryResponse = await axios.get(`${APPROVAL_SERVER_URL}/health`, { timeout: 5000 });
          this.addResult('Approval Server', true, 'Server started successfully');
        } catch (retryError) {
          this.addResult('Approval Server', false, 'Could not start server');
        }
      } else {
        this.addResult('Approval Server', false, error.message);
      }
    }
  }

  async startApprovalServer() {
    return new Promise((resolve, reject) => {
      this.serverProcess = spawn('node', ['approval-server.js'], {
        cwd: __dirname,
        stdio: 'pipe',
        detached: true
      });
      
      this.serverProcess.stdout.on('data', (data) => {
        const output = data.toString();
        if (output.includes('Approval server running')) {
          resolve();
        }
      });
      
      this.serverProcess.stderr.on('data', (data) => {
        console.error('Server error:', data.toString());
      });
      
      this.serverProcess.on('error', reject);
      
      // Timeout after 10 seconds
      setTimeout(() => reject(new Error('Server startup timeout')), 10000);
    });
  }

  async testMessageTool() {
    console.log('📤 Testing message tool restrictions...');
    
    try {
      const ApprovedMessageTool = require('./approved-message-tool.js');
      const tool = new ApprovedMessageTool();
      
      // Test platform detection
      const twitterPlatform = tool.detectPlatform('twitter');
      if (twitterPlatform !== 'twitter') {
        this.addResult('Platform Detection', false, 'Twitter not detected correctly');
        return;
      }
      
      // Test approval requirement
      const requiresApproval = tool.requiresApproval('twitter', 'send');
      if (!requiresApproval) {
        this.addResult('Approval Requirement', false, 'Twitter posting should require approval');
        return;
      }
      
      // Test non-restricted platform
      const discordRequiresApproval = tool.requiresApproval('discord', 'send');
      if (discordRequiresApproval) {
        this.addResult('Non-restricted Platform', false, 'Discord should not require approval');
        return;
      }
      
      this.addResult('Message Tool Logic', true, 'All platform detection and approval logic working');
      
    } catch (error) {
      this.addResult('Message Tool', false, error.message);
    }
  }

  async testApprovalWorkflow() {
    console.log('🔄 Testing approval workflow...');
    
    try {
      // Test approval request
      const approvalData = {
        platform: 'twitter',
        action: 'send',
        content: 'Test tweet for approval system',
        target: '@clawdbot'
      };
      
      const approvalResponse = await axios.post(`${APPROVAL_SERVER_URL}/request-approval`, approvalData);
      
      if (!approvalResponse.data.requestId) {
        this.addResult('Approval Request', false, 'No request ID returned');
        return;
      }
      
      const requestId = approvalResponse.data.requestId;
      
      // Test status check
      const statusResponse = await axios.get(`${APPROVAL_SERVER_URL}/status/${requestId}`);
      
      if (statusResponse.data.status !== 'pending') {
        this.addResult('Status Check', false, 'Request should be pending');
        return;
      }
      
      this.addResult('Approval Workflow', true, `Request ${requestId} created and tracked correctly`);
      
    } catch (error) {
      this.addResult('Approval Workflow', false, error.message);
    }
  }

  addResult(test, passed, details) {
    this.testResults.push({ test, passed, details });
    const icon = passed ? '✅' : '❌';
    console.log(`   ${icon} ${test}: ${details}`);
  }

  printResults() {
    console.log('\n📊 Test Results Summary:');
    console.log('═'.repeat(50));
    
    const passed = this.testResults.filter(r => r.passed).length;
    const total = this.testResults.length;
    
    this.testResults.forEach(result => {
      const icon = result.passed ? '✅' : '❌';
      console.log(`${icon} ${result.test.padEnd(25)} ${result.details}`);
    });
    
    console.log('═'.repeat(50));
    console.log(`${passed}/${total} tests passed`);
    
    if (passed === total) {
      console.log('\n🎉 All tests passed! Approval gate system is ready.');
      console.log('\n🚀 Next steps:');
      console.log('   1. Restart OpenClaw gateway: openclaw gateway restart');
      console.log('   2. Test with actual posting attempt');
    } else {
      console.log('\n⚠️  Some tests failed. Check configuration and try again.');
      process.exit(1);
    }
  }
}

// Run tests if called directly
if (require.main === module) {
  const tester = new SystemTester();
  tester.runAllTests().catch(console.error);
}

module.exports = SystemTester;