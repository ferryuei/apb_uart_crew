import os
from crewai import Agent, Task, Crew, LLM

os.environ["ANTHROPIC_BASE_URL"] = "https://cloud.infini-ai.com/maas/coding"
os.environ["ANTHROPIC_AUTH_TOKEN"] = "sk-cp-mcbhmyjwishbl"
os.environ["CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC"] = "1"
os.environ["ANTHROPIC_API_KEY"] = ""
os.environ["ANTHROPIC_DEFAULT_HAIKU_MODEL"] = "glm-5"
os.environ["ANTHROPIC_DEFAULT_SONNET_MODEL"] = "glm-5"
os.environ["ANTHROPIC_DEFAULT_OPUS_MODEL"] = "glm-5"

llm = LLM(
    model="glm-5",
    base_url="https://cloud.infini-ai.com/maas/coding/v1",
    api_key="sk-cp-mcbhmyjwish2il",
    temperature=0.1,
)

rtl_agent = Agent(
    role="RTL Implementation Engineer",
    goal="Design and implement APB UART peripheral in Verilog with high quality RTL code",
    backstory="""You are an experienced RTL design engineer specializing in APB peripherals.
    You have deep knowledge of AMBA APB protocol, UART communication, and digital design.
    Your code is well-structured, follows best practices, and is ready for verification.""",
    llm=llm,
    verbose=True,
)

verification_agent = Agent(
    role="Verification Engineer",
    goal="Create comprehensive verification environment and achieve 90%+ code coverage for APB UART",
    backstory="""You are a verification expert with extensive experience in SystemVerilog UVM.
    You specialize in creating robust testbenches, constrained-random testing, and achieving 
    high code coverage. You write comprehensive coverage-driven verification plans.""",
    llm=llm,
    verbose=True,
)

docs_agent = Agent(
    role="Documentation Engineer",
    goal="Organize and maintain comprehensive documentation for the APB UART design",
    backstory="""You are a technical writer specialized in hardware documentation.
    You create clear specification documents, user guides, and design descriptions.
    Your documentation is thorough, well-organized, and follows industry standards.""",
    llm=llm,
    verbose=True,
)

rtl_task = Task(
    description="""Implement a complete APB UART peripheral in Verilog with the following specifications:
    
    1. APB Slave Interface:
       - Support APB protocol (PSEL, PENABLE, PWRITE, PREADY, PSLVERR)
       - Configurable address space for control and data registers
       - Support both read and write operations
    
    2. UART Features:
       - 8N1 format (8 data bits, 1 stop bit, no parity)
       - Configurable baud rate divider
       - TX and RX FIFOs (16 depth recommended)
       - Interrupt generation for TX/RX events
    
    3. Registers:
       - RXDATA (read): Received data
       - TXDATA (write): Data to transmit
       - STATUS (read): TX/RX FIFO status, busy flags
       - CONTROL (write): Interrupt enable, FIFO clear
       - BAUDDIV (write): Baud rate divider
    
    4. Implementation Requirements:
       - Use modern Verilog (2005+)
       - Include proper clock reset handling
       - Add proper handshaking with PREADY
       - Generate clean, synthesizable code
    
    Output the Verilog files to the apb_uart_crew/rtl/ directory.""",
    expected_output="Complete Verilog RTL implementation with APB interface and UART functionality",
    agent=rtl_agent,
)

verification_task = Task(
    description="""Create comprehensive verification environment for the APB UART peripheral.
    
    Requirements:
    
    1. SystemVerilog UVM Testbench:
       - UVM testbench structure with scoreboard
       - APB driver/monitor for APB protocol
       - UART driver/monitor for UART signals
       - Sequence library for various test scenarios
    
    2. Test Cases (minimum):
       - Basic APB read/write tests
       - UART transmission test
       - UART reception test
       - FIFO overflow/underflow tests
       - Register access tests
       - Interrupt generation tests
    
    3. Coverage Goals:
       - Achieve 90%+ line/branch coverage
       - Functional coverage for protocol
       - Coverage for corner cases
    
    4. Verification Output:
       - Run simulation and report coverage
       - Generate coverage report
    
    Use the RTL files from apb_uart_crew/rtl/ as DUT.
    Output testbench to apb_uart_crew/verification/ directory.""",
    expected_output="Complete UVM testbench with 90%+ coverage report",
    agent=verification_agent,
    context=[rtl_task],
)

docs_task = Task(
    description="""Create comprehensive documentation for the APB UART peripheral.
    
    Documentation should include:
    
    1. Design Specification:
       - Overview of APB UART
       - Feature list
       - Block diagram description
    
    2. Register Description:
       - All registers with bit definitions
       - Address mapping
       - Access permissions
    
    3. Interface Description:
       - APB interface signals
       - UART interface signals
       - Timing diagrams
    
    4. Usage Guide:
       - How to configure for different baud rates
       - How to send/receive data
       - How to handle interrupts
    
    Use the RTL implementation as reference.
    Output documentation to apb_uart_crew/docs/ directory.""",
    expected_output="Complete design documentation with spec, register maps, and user guide",
    agent=docs_agent,
    context=[rtl_task],
)

crew = Crew(
    agents=[rtl_agent, verification_agent, docs_agent],
    tasks=[rtl_task, verification_task, docs_task],
    verbose=True,
)

print("Starting APB UART Design Task...")
print("=" * 60)
result = crew.kickoff()
print("=" * 60)
print("TASK COMPLETED")
print("=" * 60)
print(result)
